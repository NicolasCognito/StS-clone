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
    local effect = event.effect
    if not effect then
        table.insert(world.log, "CustomEffect called without effect data")
        return
    end

    if type(effect) == "function" then
        effect(world)
    else
        world.queue:push(effect)
    end
end

return CustomEffect
