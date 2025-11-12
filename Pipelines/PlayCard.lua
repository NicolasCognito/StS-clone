-- PLAY CARD PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card from hand to play
--
-- Context System:
-- - Cards specify context needs via card.contextProvider configuration
-- - Context is collected by CombatEngine (via user input) and stored in world.combat
-- - Cards read context from world.combat.latestContext during onPlay
-- - Context can be "stable" (persists across duplications) or "temp" (re-collected each duplication)
--
-- Handles:
-- - Check energy cost
-- - Check custom playability (if card has isPlayable function)
-- - Execute pre-play action (if card has prePlayAction function)
-- - Request context collection (sets world.combat.contextRequest)
-- - Pay energy cost
-- - Track combat statistics (Powers played, etc.)
-- - Call card.onPlay to generate events
-- - Process effect queue
-- - Schedule duplications (Double Tap, Burst, etc.) ahead of time
-- - Remove card from hand
-- - Add to discard pile (or exhaust if Corruption + Skill)
-- - Combat logging

local PlayCard = {}

local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
local GetCost = require("Pipelines.GetCost")
local Utils = require("utils")
local DuplicationHelpers = require("Pipelines.PlayCard_DuplicationHelpers")
local ClearContext = require("Pipelines.ClearContext")
local ContextProvider = require("Pipelines.ContextProvider")

local function ensureCombatContext(world)
    world.combat = world.combat or {}
    return world.combat
end

local function enterProcessingState(card)
    if card.state ~= "PROCESSING" then
        if card._previousState == nil then
            card._previousState = card.state
        end
        card.state = "PROCESSING"
    end
end

local function revertProcessingState(card)
    if card._previousState then
        card.state = card._previousState
        card._previousState = nil
    elseif card.state == "PROCESSING" then
        card.state = "HAND"
    end
end

local function prepareCardPlay(world, player, card, options)
    options = options or {}

    if card.energyPaid then
        return true
    end

    local skipEnergyCost = options.skipEnergyCost or false
    local energySpentOverride = options.energySpentOverride
    local playSource = options.playSource
    local costWhenPlayedOverride = options.costWhenPlayedOverride

    -- STEP 1: CHECK ENERGY
    local cardCost = costWhenPlayedOverride or GetCost.execute(world, player, card)
    if not skipEnergyCost and player.energy < cardCost then
        table.insert(world.log, "Not enough energy to play " .. card.name)
        return false
    end

    -- STEP 2: CHECK CUSTOM PLAYABILITY (Optional)
    if card.isPlayable then
        local playable, errorMsg = card:isPlayable(world, player)
        if not playable then
            table.insert(world.log, errorMsg or ("Cannot play " .. card.name))
            return false
        end
    end

    -- STEP 3: PRE-PLAY ACTION (Optional)
    if card.prePlayAction then
        card:prePlayAction(world, player)
    end

    -- STEP 4: PAY ENERGY
    if not skipEnergyCost then
        player.energy = player.energy - cardCost
    end

    local loggedCost = skipEnergyCost and 0 or cardCost
    local logMessage = player.id .. " played " .. card.name .. " (cost: " .. loggedCost .. ")"
    if playSource then
        logMessage = logMessage .. " via " .. playSource
    elseif skipEnergyCost then
        logMessage = logMessage .. " for free"
    end
    table.insert(world.log, logMessage)

    card.costWhenPlayed = cardCost

    if energySpentOverride ~= nil then
        card.energySpent = energySpentOverride
    elseif card.cost == "X" and skipEnergyCost then
        card.energySpent = 0
    else
        card.energySpent = cardCost
    end

    -- Chemical X: Add bonus to X cost cards
    if card.cost == "X" then
        local chemicalX = Utils.getRelic(player, "Chemical_X")
        if chemicalX then
            card.energySpent = card.energySpent + chemicalX.xCostBonus
            table.insert(world.log, "Chemical X activated! (X + " .. chemicalX.xCostBonus .. ")")
        end
    end

    card.energyPaid = true
    ensureCombatContext(world).deferStableContextClear = true
    enterProcessingState(card)
    return true
end

local function finalizeCardPlay(world, card)
    card.energyPaid = nil
    card._pendingContextPhase = nil
    card._effectInitialized = nil
    card._echoFormApplied = nil
    card._runActive = nil
    card._pendingEntries = nil
    card._previousState = nil
    ensureCombatContext(world).deferStableContextClear = false
    ClearContext.execute(world)
end

local function enqueueCardEntries(world, player, card, options)
    local queue = world.cardQueue
    if not queue then
        error("Card queue is not initialized. Did you forget to start combat?")
    end

    local prepared = prepareCardPlay(world, player, card, options)
    if prepared ~= true then
        return prepared
    end

    local replayPlan = DuplicationHelpers.buildReplayPlan(world, player, card)
    local totalEntries = 1 + #replayPlan

    -- Push duplication entries first so LIFO order executes initial play before replays
    for i = #replayPlan, 1, -1 do
        local sourceName = replayPlan[i]
        queue:push({
            card = card,
            player = player,
            options = options,
            replaySource = sourceName,
            isInitial = false,
            isLast = (i == #replayPlan),
            phase = "duplication",
            skipDiscard = (i ~= #replayPlan)
        })
    end

    -- Initial play runs last (top of stack)
    queue:push({
        card = card,
        player = player,
        options = options,
        replaySource = nil,
        isInitial = true,
        isLast = (#replayPlan == 0),
        phase = "main",
        skipDiscard = (#replayPlan ~= 0)
    })

    card._runActive = true
    card._pendingEntries = totalEntries
    return true
end

-- EXECUTE CARD EFFECT (Steps 6-9)
-- This is the "bracketed section" that gets replayed for effects like Double Tap
-- skipDiscard: if true, don't move card to discard pile (for replays where card is already in a pile)
-- Context is read from world.combat.latestContext
function PlayCard.executeCardEffect(world, player, card, skipDiscard, phase)
    phase = phase or "main"

    -- STEP 6: TRACK STATISTICS (only once per actual execution)
    if not card._effectInitialized then
        card._effectInitialized = true

        if card.type == "POWER" then
            world.combat.powersPlayedThisCombat = world.combat.powersPlayedThisCombat + 1
        end

        if card.type == "ATTACK" then
            world.penNibCounter = world.penNibCounter + 1
        end

        -- STEP 7: EXECUTE CARD EFFECT
        if card.onPlay then
            card:onPlay(world, player)
        end

        world.queue:push({
            type = "AFTER_CARD_PLAYED",
            player = player
        })
    end

    -- STEP 8: PROCESS EVENT QUEUE
    local queueResult = ProcessEventQueue.execute(world)
    if type(queueResult) == "table" and queueResult.needsContext then
        card._pendingContextPhase = phase
        return queueResult
    end

    -- STEP 9: CARD CLEANUP (Discard or Exhaust)
    local shouldExhaust = false
    local exhaustSource = nil

    if card.exhausts then
        shouldExhaust = true
        exhaustSource = exhaustSource or "SelfExhaust"
    end

    if Utils.hasPower(player, "Corruption") and card.type == "SKILL" then
        shouldExhaust = true
        exhaustSource = "Corruption"
    end

    if shouldExhaust then
        world.queue:push({
            type = "ON_EXHAUST",
            card = card,
            source = exhaustSource
        })
        queueResult = ProcessEventQueue.execute(world)
        if type(queueResult) == "table" and queueResult.needsContext then
            card._pendingContextPhase = phase
            return queueResult
        end
    elseif not skipDiscard then
        world.queue:push({
            type = "ON_DISCARD",
            card = card,
            player = player
        })
        queueResult = ProcessEventQueue.execute(world)
        if type(queueResult) == "table" and queueResult.needsContext then
            card._pendingContextPhase = phase
            return queueResult
        end

    end

    return true
end

local function resolveEntry(world, entry)
    if not entry then
        return nil
    end

    local card = entry.card
    local player = entry.player
    local skipDiscard = entry.skipDiscard
    local phase = entry.phase or (entry.isInitial and "main" or "duplication")

    if not entry.resuming then
        card._effectInitialized = nil
    end

    if entry.replaySource and not entry.replayLogged then
        table.insert(world.log, entry.replaySource .. " triggers!")
        entry.replayLogged = true
    end

    local result = PlayCard.executeCardEffect(world, player, card, skipDiscard, phase)
    if type(result) == "table" and result.needsContext then
        entry.phase = card._pendingContextPhase or phase
        entry.resuming = true
        world.cardQueue:push(entry)
        return result
    end

    card._effectInitialized = nil
    card._pendingContextPhase = nil
    entry.resuming = nil

    if entry.isLast then
        finalizeCardPlay(world, card)
    end

    return true
end

function PlayCard.resolveQueuedEntry(world, entry)
    return resolveEntry(world, entry)
end

function PlayCard.execute(world, player, card, options)
    options = options or {}

    if not card._runActive then
        local enqueueResult = enqueueCardEntries(world, player, card, options)
        if enqueueResult ~= true then
            return enqueueResult
        end
    end

    local queueResult = ProcessEventQueue.execute(world)
    if type(queueResult) == "table" and queueResult.needsContext then
        return queueResult
    end

    return true
end

function PlayCard.autoExecute(world, player, card, options)
    options = options or {}

    while true do
        local result = PlayCard.execute(world, player, card, options)

        if result == true then
            return true
        end

        if type(result) == "table" and result.needsContext then
            local request = world.combat and world.combat.contextRequest
            if not request then
                return false
            end

            local context = ContextProvider.execute(world, player, request.contextProvider, request.card)
            if not context then
                world.combat.contextRequest = nil
                return false
            end

            if request.stability == "stable" then
                world.combat.stableContext = context
            else
                world.combat.tempContext = context
            end

            world.combat.contextRequest = nil
        else
            revertProcessingState(card)
            return result
        end
    end
end

function PlayCard.queueForcedReplay(card, sourceName, count)
    count = count or 1
    if count <= 0 then
        return
    end

    card._forcedReplays = card._forcedReplays or {}
    for _ = 1, count do
        table.insert(card._forcedReplays, sourceName or "Forced Replay")
    end
end

return PlayCard
