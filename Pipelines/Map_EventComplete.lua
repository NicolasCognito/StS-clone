-- MAP EVENT COMPLETE PIPELINE
-- Handles cleanup when a MapEvent signals it is finished.

local Map_EventComplete = {}

function Map_EventComplete.execute(world, event)
    world.currentEvent = nil
    if world.mapEvent then
        world.mapEvent = nil
    end

    if world.log then
        table.insert(world.log, "Map event complete: " .. (event and event.result or "complete"))
    else
        print("Map event complete: " .. (event and event.result or "complete"))
    end
end

return Map_EventComplete
