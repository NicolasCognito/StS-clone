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
    -- Note: tempContext is NOT cleared here - it should be cleared manually by the code
    -- that created it, after it's done using it. This allows pipelines to set tempContext
    -- before calling ProcessEventQueue without it being cleared prematurely.
    -- Stable context is cleared by separators in CardQueue, not here.
    if world.combat then
        -- Don't clear tempContext here
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
end

return QueueOver
