-- CUSTOM EFFECT PIPELINE
-- Takes whatever is pushed inside and pushes it to the queue
--
-- Event structure:
-- {
--   type = "ON_CUSTOM_EFFECT",
--   effect = { ... }  -- The actual event to push to the queue
-- }
--
-- This allows cards to generate dynamic/meta events

local CustomEffect = {}

function CustomEffect.execute(world, event)
    if event.effect then
        world.queue:push(event.effect)
    else
        table.insert(world.log, "CustomEffect called without effect data")
    end
end

return CustomEffect
