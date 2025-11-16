-- PLAYCARD HELPER FUNCTIONS
-- Supporting functions for PlayCard.lua to improve clarity and maintainability
--
-- These functions handle specific sub-tasks of card playing:
-- - Card cleanup (exhaust vs discard determination)
-- - Energy cost calculation (including X-costs and Chemical X)
-- - Play logging

local PlayCard_Helpers = {}

local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
local Utils = require("utils")

-- HANDLE CARD CLEANUP
-- Determines whether a card should be exhausted or discarded after playing
-- and queues the appropriate event.
--
-- Exhaust conditions:
-- 1. options.forcedExhaust is set (e.g., Havoc forces exhaust)
-- 2. Card has exhausts = true
-- 3. Card is a Skill and player has Corruption power
--
-- Parameters:
--   world: game state
--   player: the player
--   card: the card being cleaned up
--   options: play options (may contain forcedExhaust)
--
-- Returns:
--   true on success
--   {needsContext = true} if context is required (rare for cleanup, but possible)
function PlayCard_Helpers.handleCardCleanup(world, player, card, options)
    options = options or {}
    local shouldExhaust = false
    local exhaustSource = nil

    -- Check if forced exhaust (e.g., Havoc played this card)
    if options.forcedExhaust then
        shouldExhaust = true
        exhaustSource = options.forcedExhaust  -- Source name (e.g., "Havoc")
    end

    -- Check if card self-exhausts
    if card.exhausts then
        shouldExhaust = true
        exhaustSource = "SelfExhaust"
    end

    -- Check if Corruption forces exhaust (Skills only)
    if Utils.hasPower(player, "Corruption") and card.type == "SKILL" then
        shouldExhaust = true
        exhaustSource = "Corruption"
    end

    -- Queue exhaust or discard event and process
    if shouldExhaust then
        world.queue:push({
            type = "ON_EXHAUST",
            card = card,
            source = exhaustSource
        })
    else
        world.queue:push({
            type = "ON_DISCARD",
            card = card,
            player = player
        })
    end

    -- Process the event queue (exhaust/discard might trigger other effects)
    local queueResult = ProcessEventQueue.execute(world)
    if type(queueResult) == "table" and queueResult.needsContext then
        return queueResult
    end

    return true
end

-- CALCULATE ENERGY SPENT
-- Calculates how much energy was "spent" on a card for X-cost purposes
-- Handles X-costs, energy overrides, and Chemical X relic bonus
--
-- Parameters:
--   world: game state
--   player: the player
--   card: the card being played
--   cardCost: the actual energy cost paid
--   options: play options (may contain energySpentOverride)
--
-- Returns:
--   energySpent: the amount to use for X-cost calculations
function PlayCard_Helpers.calculateEnergySpent(world, player, card, cardCost, options)
    local energySpent

    -- Check for manual override (used by auto-play systems like Havoc)
    if options.energySpentOverride ~= nil then
        energySpent = options.energySpentOverride
    -- X-cost cards played for free (auto-play) default to X=0
    elseif card.cost == "X" and options.auto then
        energySpent = 0
    -- Normal case: energySpent = cost paid
    else
        energySpent = cardCost
    end

    -- Chemical X relic: Add bonus to X-cost cards
    if card.cost == "X" then
        local chemicalX = Utils.getRelic(player, "Chemical_X")
        if chemicalX then
            energySpent = energySpent + chemicalX.xCostBonus
            table.insert(world.log, "Chemical X activated! (X + " .. chemicalX.xCostBonus .. ")")
        end
    end

    return energySpent
end

-- FORMAT CARD PLAY LOG MESSAGE
-- Creates a formatted log message for card plays
-- Handles various play modes: normal, free, via other cards
--
-- Parameters:
--   player: the player
--   card: the card being played
--   options: play options (auto, playSource, etc.)
--   cardCost: the energy cost paid
--
-- Returns:
--   logMessage: formatted string for game log
function PlayCard_Helpers.formatPlayLog(player, card, options, cardCost)
    local auto = options.auto or options.skipEnergyCost or false
    local playSource = options.playSource

    local loggedCost = auto and 0 or cardCost
    local logMessage = player.id .. " played " .. card.name .. " (cost: " .. loggedCost .. ")"

    if playSource then
        logMessage = logMessage .. " via " .. playSource
    elseif auto then
        logMessage = logMessage .. " for free"
    end

    return logMessage
end

return PlayCard_Helpers
