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
    -- Temp context should not persist once queue resolves
    world.combat.tempContext = nil

    -- Allow stable context to persist while a card (or its duplications)
    -- is still resolving. Outside those windows, clear it.
    if not world.combat.deferStableContextClear then
        world.combat.stableContext = nil
    end

    if world.cardQueue and not world.cardQueue:isEmpty() then
        return getResolveCard().execute(world)
    end
end

return QueueOver
