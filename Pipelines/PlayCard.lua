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

    player.status = player.status or {}
    if card.type == "ATTACK" and player.status.entangled and player.status.entangled > 0 then
        table.insert(world.log, player.name .. " is Entangled and cannot play attacks")
        return false
    end

    -- Check card play limits (Velvet Choker, Normality)
    -- Skip for auto-cast cards (like Havoc) since they were already validated
    if world.combat and not options.auto then
        local limit = Utils.getCardPlayLimit(world, player)
        if world.combat.cardsPlayedThisTurn >= limit then
            table.insert(world.log, "Cannot play more than " .. limit .. " cards this turn")
            return false
        end
    end

    local auto = options.auto or options.skipEnergyCost or false  -- Support both names for compatibility
    local energySpentOverride = options.energySpentOverride
    local playSource = options.playSource
    local costWhenPlayedOverride = options.costWhenPlayedOverride

    -- STEP 1: CHECK ENERGY (skip for auto-cast)
    local cardCost = costWhenPlayedOverride or GetCost.execute(world, player, card)
    if not auto and player.energy < cardCost then
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

    -- STEP 4: PAY ENERGY (skip for auto-cast)
    if not auto then
        player.energy = player.energy - cardCost
    end

    -- Logging
    local loggedCost = auto and 0 or cardCost
    local logMessage = player.id .. " played " .. card.name .. " (cost: " .. loggedCost .. ")"
    if playSource then
        logMessage = logMessage .. " via " .. playSource
    elseif auto then
        logMessage = logMessage .. " for free"
    end
    table.insert(world.log, logMessage)

    -- Set cost information (needed even for auto-cast for X-cost cards, etc.)
    card.costWhenPlayed = cardCost

    if energySpentOverride ~= nil then
        card.energySpent = energySpentOverride
    elseif card.cost == "X" and auto then
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
    card._previousLastPlayedCard = world.lastPlayedCard  -- Save for restoration if card is canceled
    enterProcessingState(card)
    return true
end

local function finalizeCardPlay(world, card)
    -- Clean up temporary card flags
    -- Stable context is cleared by separators, not here
    card.energyPaid = nil
    card._runActive = nil
    card._previousState = nil
    card._effectInitialized = nil
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

    -- Build duplication plan
    local replayPlan = DuplicationHelpers.buildReplayPlan(world, player, card)

    -- Create shadow copies for each duplication
    -- Shadow copies are REAL card instances that inherit all prepared state from the original
    local shadowCopies = {}
    local loggedSources = {}  -- Track which sources we've logged
    for i, sourceName in ipairs(replayPlan) do
        -- Log duplication trigger (once per source)
        if not loggedSources[sourceName] then
            table.insert(world.log, sourceName .. " triggers!")
            loggedSources[sourceName] = true
        end

        local shadow = Utils.deepCopyCard(card)
        shadow.isShadow = true
        shadow.id = Utils.generateGUID()  -- Unique ID for tracking
        shadow.originalCardName = card.name
        shadow.duplicationSource = sourceName  -- "Double Tap", "Echo Form", etc.
        -- Shadow inherits all prepared state from original
        shadow.costWhenPlayed = card.costWhenPlayed
        shadow.energySpent = card.energySpent
        shadow.energyPaid = card.energyPaid
        shadow.state = "PROCESSING"
        -- Shadow should NOT inherit execution state flags
        shadow._effectInitialized = nil

        table.insert(world.DuplicationShadowCards, shadow)
        table.insert(shadowCopies, shadow)
    end

    -- Push entries to CardQueue (LIFO) with separators bracketing the execution group
    -- Separators ensure stable context is cleared before and after this card+duplicates

    -- Bottom separator: clears stable context AFTER this card group finishes (pops last)
    queue:pushSeparator()

    -- Push shadow copies in reverse order (LIFO) so they execute before the original
    for i = #shadowCopies, 1, -1 do
        queue:push({
            card = shadowCopies[i],
            player = player,
            options = options
        })
    end

    -- Push original card entry (always executes, shadows are additional plays)
    queue:push({
        card = card,
        player = player,
        options = options
    })

    -- Top separator: clears stable context BEFORE this card group starts (pops first)
    queue:pushSeparator()

    card._runActive = true
    return true
end

-- EXECUTE CARD EFFECT
-- Executes a card's effect. Works with both original cards and shadow copies.
-- Each card (original or shadow) is executed independently with full game mechanics.
function PlayCard.executeCardEffect(world, player, card)
    -- Only execute effect and push events if not already initialized
    -- This prevents duplicate event pushing when resuming after context collection
    if not card._effectInitialized then
        card._effectInitialized = true

        -- STEP 1: TRACK STATISTICS (for ALL cards, including shadows)
        if card.type == "POWER" then
            world.combat.powersPlayedThisCombat = world.combat.powersPlayedThisCombat + 1

            -- Storm: Channel 1 Lightning when playing Power cards (ALL powers trigger this)
            if player.status and player.status.storm and player.status.storm > 0 then
                world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Lightning"})
                table.insert(world.log, "Storm triggered!")
            end
        end

        -- Pen Nib: ALL attacks increment counter (including shadow copies)
        if card.type == "ATTACK" then
            world.penNibCounter = world.penNibCounter + 1
        end

        -- Enhanced logging for shadow copies
        if card.isShadow then
            local source = card.duplicationSource or "Duplication"
            table.insert(world.log, "  → " .. card.originalCardName .. " (" .. source .. ")")
        end

        -- STEP 2: EXECUTE CARD EFFECT
        if card.onPlay then
            card:onPlay(world, player)
        end

        -- STEP 3: TRACK CURRENT EXECUTING CARD
        world.combat.currentExecutingCard = {
            type = card.type,
            name = card.isShadow and card.originalCardName or card.name,
            isShadow = card.isShadow
        }

        world.queue:push({
            type = "AFTER_CARD_PLAYED",
            player = player
        })
    end

    -- STEP 4: PROCESS EVENT QUEUE (always do this, even when resuming)
    local queueResult = ProcessEventQueue.execute(world)
    if type(queueResult) == "table" and queueResult.needsContext then
        return queueResult
    end

    -- STEP 5: CARD CLEANUP (Discard or Exhaust)
    -- Each card independently handles its own discard/exhaust
    local shouldExhaust = false
    local exhaustSource = nil

    if card.exhausts then
        shouldExhaust = true
        exhaustSource = "SelfExhaust"
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
            return queueResult
        end
    else
        -- Discard the card
        world.queue:push({
            type = "ON_DISCARD",
            card = card,
            player = player
        })
        queueResult = ProcessEventQueue.execute(world)
        if type(queueResult) == "table" and queueResult.needsContext then
            return queueResult
        end
    end

    return true
end

local function resolveEntry(world, entry)
    if not entry then
        return nil
    end

    -- Handle separator entries (skip them - they're handled by ResolveCard)
    if entry.type == "SEPARATOR" then
        return true
    end

    local card = entry.card
    local player = entry.player

    -- STABLE CONTEXT VALIDATION
    -- Check if stable context is still valid before executing card
    if card.stableContextValidator then
        local isValid = card.stableContextValidator(world, world.combat.stableContext, card)

        if not isValid then
            -- Give card a chance to fix invalid context
            if card.onStableContextInvalidated then
                card:onStableContextInvalidated(world)
            end

            -- Re-validate after giving card a chance to fix
            isValid = card.stableContextValidator(world, world.combat.stableContext, card)

            if not isValid then
                -- Still invalid - cancel card execution
                local cardName = card.isShadow and card.originalCardName or card.name
                table.insert(world.log, cardName .. " canceled - target no longer valid")

                -- Finalize original card (shadows are cleaned up at end of turn)
                if not card.isShadow then
                    finalizeCardPlay(world, card)
                end

                return true  -- Return success to continue processing queue
            end
        end
    end

    -- Execute the card effect
    local result = PlayCard.executeCardEffect(world, player, card)
    if type(result) == "table" and result.needsContext then
        -- Need context - push entry back to queue to resume later
        entry.resuming = true
        world.cardQueue:push(entry)
        return result
    end

    -- Finalize original card after execution (shadows are cleaned up at end of turn)
    if not card.isShadow then
        finalizeCardPlay(world, card)
    end

    return true
end

function PlayCard.resolveQueuedEntry(world, entry)
    return resolveEntry(world, entry)
end

function PlayCard.execute(world, player, card, options)
    options = options or {}

    -- Auto-cast mode: automatically handle context collection
    if options.auto then
        while true do
            -- Enqueue card if not already active
            if not card._runActive then
                local enqueueResult = enqueueCardEntries(world, player, card, options)
                if enqueueResult ~= true then
                    revertProcessingState(card)
                    return enqueueResult
                end
            end

            -- Process event queue
            local queueResult = ProcessEventQueue.execute(world)

            -- If no context needed, we're done
            if queueResult == true then
                return true
            end

            -- If context needed, automatically collect it
            if type(queueResult) == "table" and queueResult.needsContext then
                local request = world.combat and world.combat.contextRequest
                if not request then
                    revertProcessingState(card)
                    return false
                end

                -- Auto-collect context
                local context = ContextProvider.execute(world, player, request.contextProvider, request.card)
                if not context then
                    world.combat.contextRequest = nil
                    revertProcessingState(card)
                    return false
                end

                -- Store context based on stability
                if request.stability == "stable" then
                    world.combat.stableContext = context
                else
                    world.combat.tempContext = context
                end

                world.combat.contextRequest = nil
                -- Continue loop to process with collected context
            else
                -- Unexpected result
                revertProcessingState(card)
                return queueResult
            end
        end
    else
        -- Normal mode: return to caller when context is needed
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
