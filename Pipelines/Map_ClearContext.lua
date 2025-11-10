-- MAP CLEAR CONTEXT PIPELINE
-- Mirrors the combat context cleanup for map events.

local Map_ClearContext = {}

function Map_ClearContext.execute(world, event)
    if not world or not world.mapEvent then
        return
    end

    local target = (event and event.target) or "temp"

    if target == "temp" or target == "both" then
        world.mapEvent.tempContext = nil
    end

    if target == "stable" or target == "both" then
        world.mapEvent.stableContext = nil
    end
end

return Map_ClearContext
