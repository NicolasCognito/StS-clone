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

function QueueOver.execute(world)
    print("DEBUG: EventQueueOver called, CardQueue empty: " .. tostring(not world.cardQueue or world.cardQueue:isEmpty()))
    -- Temp context should not persist once queue resolves
    if world.combat then
        world.combat.tempContext = nil

        -- Allow stable context to persist while a card (or its duplications)
        -- is still resolving. Outside those windows, clear it.
        if not world.combat.deferStableContextClear then
            world.combat.stableContext = nil
        end
    end

    -- Process next card in CardQueue if any
    if world.cardQueue and not world.cardQueue:isEmpty() then
        print("DEBUG: CardQueue not empty, calling ResolveCard")
        return getResolveCard().execute(world)
    end

    -- CardQueue is empty - all card executions (including duplications) are done
    -- Now update lastPlayedCard from currentExecutingCard
    print("DEBUG: CardQueue empty, checking currentExecutingCard: " .. tostring(world.combat and world.combat.currentExecutingCard ~= nil))
    if world.combat and world.combat.currentExecutingCard then
        print("DEBUG: Updating lastPlayedCard to " .. world.combat.currentExecutingCard.name)
        world.lastPlayedCard = {
            type = world.combat.currentExecutingCard.type,
            name = world.combat.currentExecutingCard.name
        }
        print("DEBUG: lastPlayedCard set to " .. world.lastPlayedCard.name)
        -- Clear currentExecutingCard so next card doesn't inherit it
        world.combat.currentExecutingCard = nil
    end
end

return QueueOver
