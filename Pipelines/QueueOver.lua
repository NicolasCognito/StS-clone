-- QUEUE OVER PIPELINE
-- Executes when the event queue becomes empty
-- Handles cleanup and state management between cards/actions
--
-- Responsibilities:
-- - Clear stable context (enemy targets, etc.) for next card
-- - Future: End-of-action cleanup, triggers, etc.

local QueueOver = {}

function QueueOver.execute(world)
    -- Temp context should not persist once queue resolves
    world.combat.tempContext = nil

    -- Allow stable context to persist while a card (or its duplications)
    -- is still resolving. Outside those windows, clear it.
    if not world.combat.deferStableContextClear then
        world.combat.stableContext = nil
    end
end

return QueueOver
