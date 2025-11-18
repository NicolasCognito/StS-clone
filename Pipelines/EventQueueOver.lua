-- QUEUE OVER PIPELINE
-- Executes when the event queue becomes empty
-- Handles cleanup and state management between cards/actions
--
-- Responsibilities:
-- - Clear stable context (enemy targets, etc.) for next card
-- - Trigger next queued card (if any) via ResolveCard

local QueueOver = {}

local resolver
local function getResolveCard()
    if not resolver then
        resolver = require("Pipelines.ResolveCard")
    end
    return resolver
end

local Utils = require("utils")

function QueueOver.execute(world)
    -- Temp context should not persist once queue resolves
    if world.combat then
        world.combat.tempContext = nil
        -- Note: Stable context is cleared by separators in CardQueue, not here
    end

    -- Process next card in CardQueue if any
    if world.cardQueue and not world.cardQueue:isEmpty() then
        return getResolveCard().execute(world)
    end

    -- CardQueue is empty - all card executions (including duplications) are done
    -- Clear currentExecutingCard so next card doesn't inherit it
    -- (lastPlayedCard update moved to AfterCardPlayed for per-execution tracking)
    if world.combat and world.combat.currentExecutingCard then
        world.combat.currentExecutingCard = nil
    end

    -- Unceasing Top: If hand is empty during player's turn, draw a card
    -- Only trigger when:
    -- 1. It's the player's turn (not enemy turn)
    -- 2. Hand is empty
    -- 3. No autocasting pending (prevents triggering during Mayhem/etc)
    -- 4. Player has Unceasing Top relic
    if world.combat and world.combat.isPlayerTurn and world.player then
        local handCount = Utils.getCardCountByState(world.player.combatDeck, "HAND")
        local hasUnceasingTop = Utils.hasRelic(world.player, "UnceasingTop") or Utils.hasRelic(world.player, "Unceasing_Top")
        local noAutocasting = not world.combat.autocastingNextTopCards or world.combat.autocastingNextTopCards == 0

        if handCount == 0 and hasUnceasingTop and noAutocasting then
            -- Draw one card
            world.queue:push({type = "ON_DRAW"})
            table.insert(world.log, "Unceasing Top: Drew 1 card (hand was empty)")

            -- Process the draw (will recursively call QueueOver if hand still empty)
            local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
            return ProcessEventQueue.execute(world)
        end
    end
end

return QueueOver
