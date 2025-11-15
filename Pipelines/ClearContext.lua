-- CLEAR CONTEXT PIPELINE
-- Allows explicit control over clearing combat context caches
--
-- Event/options table fields:
-- - clearStable (bool, default true)
-- - clearTemp (bool, default false) -- deprecated with indexed tempContext
-- - clearRequest (bool, default true)
--
-- Note: With indexed tempContext, manual clearing is no longer needed.
-- tempContext is cleared automatically at turn boundaries.
--
-- This pipeline can be invoked directly or through the event queue via
--   { type = "CLEAR_CONTEXT", ...options }

local ClearContext = {}

function ClearContext.execute(world, options)
    options = options or {}

    if not world.combat then
        return
    end

    local clearStable = options.clearStable
    if clearStable == nil then
        clearStable = true
    end

    local clearTemp = options.clearTemp
    if clearTemp == nil then
        clearTemp = false  -- Default to false with indexed tempContext
    end

    local clearRequest = options.clearRequest
    if clearRequest == nil then
        clearRequest = true
    end

    if clearStable then
        world.combat.stableContext = nil
    end

    if clearTemp then
        world.combat.tempContext = {}  -- Reset to empty indexed table
    end

    if clearRequest then
        world.combat.contextRequest = nil
    end
end

return ClearContext
