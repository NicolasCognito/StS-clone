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
-- Context available to card.onPlay:
-- - For "enemy" context: world.combat.latestContext is enemy entity
-- - For card selection contexts: world.combat.latestContext is array of cards
-- - For "none" context: world.combat.latestContext is nil
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
-- - Handle card duplication (Double Tap, etc.)
-- - Remove card from hand
-- - Add to discard pile (or exhaust if Corruption + Skill)
-- - Combat logging
--
-- Custom Playability:
-- Some cards (Grand Finale, etc.) have special requirements beyond energy.
-- If card.isPlayable exists, it's called to validate if card can be played.
-- Returns: true if playable, false + optional error message if not.
--
-- Pre-Play Actions:
-- Some cards (Discovery, etc.) need to set up choices BEFORE context collection.
-- If card.prePlayAction exists, it's called before context collection.
-- Example: Discovery generates 3 random cards with state="DRAFT", then contextProvider
--          filters for DRAFT cards for player to choose from.
--
-- Additional Context During Play:
-- Cards can request additional context during their onPlay by setting world.combat.contextRequest.
-- Example: Dagger Throw first uses enemy context, then during onPlay requests card selection.
-- CombatEngine will collect the additional context and call PlayCard again to continue.

local PlayCard = {}

local ProcessEffectQueue = require("Pipelines.ProcessEffectQueue")
local GetCost = require("Pipelines.GetCost")
local ContextProvider = require("Pipelines.ContextProvider")
local Utils = require("utils")
local DuplicationHelpers = require("Pipelines.PlayCard_DuplicationHelpers")

-- EXECUTE CARD EFFECT (Steps 6-9)
-- This is the "bracketed section" that gets replayed for effects like Double Tap
-- skipDiscard: if true, don't move card to discard pile (for replays where card is already in a pile)
-- Context is read from world.combat.latestContext
function PlayCard.executeCardEffect(world, player, card, skipDiscard)
    -- STEP 6: TRACK STATISTICS
    -- Track combat statistics
    if card.type == "POWER" then
        world.combat.powersPlayedThisCombat = world.combat.powersPlayedThisCombat + 1
    end

    -- Increment Pen Nib counter for Attack cards
    if card.type == "ATTACK" then
        world.penNibCounter = world.penNibCounter + 1
    end

    -- STEP 7: EXECUTE CARD EFFECT
    -- Call card's onPlay function
    -- Card reads context from world.combat.latestContext if needed
    if card.onPlay then
        card:onPlay(world, player)
    end

    -- Push AfterCardPlayed event to queue (processed after card effects)
    world.queue:push({
        type = "AFTER_CARD_PLAYED",
        player = player
    })

    -- STEP 8: PROCESS EFFECT QUEUE
    -- Process all events from the queue
    local queueResult = ProcessEffectQueue.execute(world)
    if queueResult and queueResult.needsContext then
        return queueResult  -- Pause and propagate context request
    end

    -- STEP 9: CARD CLEANUP (Discard or Exhaust)
    -- Determine where card goes after being played
    -- Check if card should be exhausted (Corruption for Skills, or card has exhaust property)
    local shouldExhaust = false
    local exhaustSource = nil

    -- Corruption: Skills are exhausted
    if Utils.hasPower(player, "Corruption") and card.type == "SKILL" then
        shouldExhaust = true
        exhaustSource = "Corruption"
    end

    -- TODO: Card-specific exhaust (e.g., Offering, True Grit+, etc.)
    -- if card.exhausts then
    --     shouldExhaust = true
    --     exhaustSource = "SelfExhaust"
    -- end

    if shouldExhaust then
        -- Push exhaust event to queue
        world.queue:push({
            type = "ON_EXHAUST",
            card = card,
            source = exhaustSource
        })
        queueResult = ProcessEffectQueue.execute(world)
        if queueResult and queueResult.needsContext then
            return queueResult
        end
    elseif not skipDiscard then
        -- Normal discard via event queue (skip for replays where card is already in a pile)
        world.queue:push({
            type = "ON_DISCARD",
            card = card,
            player = player
        })
        queueResult = ProcessEffectQueue.execute(world)
        if queueResult and queueResult.needsContext then
            return queueResult
        end
    end
end

function PlayCard.execute(world, player, card)
    -- Check if this is a continuation (card already paid energy)
    if not card.energyPaid then
        -- STEP 1: CHECK ENERGY
        local cardCost = GetCost.execute(world, player, card)
        if player.energy < cardCost then
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
        player.energy = player.energy - cardCost
        table.insert(world.log, player.id .. " played " .. card.name .. " (cost: " .. cardCost .. ")")

        card.energySpent = cardCost
        card.costWhenPlayed = cardCost

        -- Chemical X: Add bonus to X cost cards
        if card.cost == "X" then
            local chemicalX = Utils.getRelic(player, "Chemical_X")
            if chemicalX then
                card.energySpent = card.energySpent + chemicalX.xCostBonus
                table.insert(world.log, "Chemical X activated! (X + " .. chemicalX.xCostBonus .. ")")
            end
        end

        card.energyPaid = true
    end

    -- STEP 5: Execute card effect (may pause for context collection)
    local effectResult = PlayCard.executeCardEffect(world, player, card, false)
    if effectResult and effectResult.needsContext then
        return effectResult  -- Pause and return to CombatEngine
    end

    -- STEP 6: DUPLICATION LOOP
    while true do
        local shouldReplay, source = DuplicationHelpers.shouldBePlayedAgain(world, player, card)
        if not shouldReplay then
            break
        end

        table.insert(world.log, source .. " triggers!")
        effectResult = PlayCard.executeCardEffect(world, player, card, true)  -- skipDiscard=true
        if effectResult and effectResult.needsContext then
            return effectResult  -- Pause for context collection in duplication
        end
    end

    -- Clean up for next card
    card.energyPaid = nil

    return true
end

return PlayCard
