-- PLAY CARD PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card from hand to play
-- providedContext: optional pre-provided context (enemy entity, cards array, or nil)
--                  If nil, will be auto-collected by ContextProvider
--
-- Context parameter passed to card.onPlay:
-- - For "enemy" context: enemy entity
-- - For "cards_in_*" contexts: array of cards (always array, even for single card)
-- - For "none" context: nil
--
-- Handles:
-- - Collect context (via ContextProvider if not provided)
-- - Pay energy cost
-- - Track combat statistics (Powers played, etc.)
-- - Call card.onPlay to generate events
-- - Process effect queue
-- - Remove card from hand
-- - Add to discard pile (or exhaust if Corruption + Skill)
-- - Combat logging

local PlayCard = {}

local ProcessEffectQueue = require("Pipelines.ProcessEffectQueue")
local GetCost = require("Pipelines.GetCost")
local ContextProvider = require("Pipelines.ContextProvider")
local Utils = require("utils")

function PlayCard.execute(world, player, card, providedContext)
    -- STEP 1: COLLECT CONTEXT
    -- Get context via ContextProvider if not explicitly provided
    local context = providedContext
    if context == nil then
        context = ContextProvider.execute(world, player, card)
    end

    -- Validate that context exists when needed
    local contextType = ContextProvider.getContextType(card)
    if contextType ~= "none" and context == nil then
        table.insert(world.log, "Card " .. card.name .. " requires context of type " .. contextType)
        return false
    end

    -- STEP 2: CHECK ENERGY
    -- Get the current cost of the card (allows for dynamic cost calculation)
    local cardCost = GetCost.execute(world, player, card)

    -- Check if player has enough energy
    if player.energy < cardCost then
        table.insert(world.log, "Not enough energy to play " .. card.name)
        return false
    end

    -- Pay energy cost
    player.energy = player.energy - cardCost
    table.insert(world.log, player.id .. " played " .. card.name .. " (cost: " .. cardCost .. ")")

    -- STEP 3: TRACK STATISTICS
    -- Track combat statistics
    if card.type == "POWER" then
        world.combat.powersPlayedThisCombat = world.combat.powersPlayedThisCombat + 1
    end

    -- STEP 4: EXECUTE CARD EFFECT
    -- Call card's onPlay function with context
    -- Context can be: enemy entity, cards array, or nil (depending on contextType)
    if card.onPlay then
        card:onPlay(world, player, context)
    end

    -- STEP 5: PROCESS EFFECT QUEUE
    -- Process all events from the queue
    ProcessEffectQueue.execute(world)

    -- STEP 6: CARD CLEANUP (Discard or Exhaust)
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
        ProcessEffectQueue.execute(world)
    else
        -- Normal discard
        card.state = "DISCARD_PILE"
    end

    return true
end

return PlayCard
