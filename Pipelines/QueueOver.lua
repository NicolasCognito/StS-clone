-- QUEUE OVER PIPELINE
-- Executes when the event queue becomes empty
-- Handles cleanup and state management between cards/actions
--
-- Responsibilities:
-- - Clear stable context (enemy targets, etc.) for next card
-- - Future: End-of-action cleanup, triggers, etc.

local QueueOver = {}

function QueueOver.execute(world)
    -- Clear context for next card/action
    -- Stable context should not persist across different cards
    world.combat.stableContext = nil
    world.combat.tempContext = nil
end

return QueueOver
