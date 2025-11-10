-- MAP MAP-QUEUE PIPELINE
-- Provides a queue outside of combat so overworld/map events can enqueue verbs
-- that will be resolved by map-specific processors.

local EventQueue = require("Pipelines.EventQueue")

local Map_MapQueue = {}

local function ensureQueue(world)
    if not world.mapQueue then
        world.mapQueue = EventQueue.new()
    end
    return world.mapQueue
end

function Map_MapQueue.push(world, event, strategy)
    local queue = ensureQueue(world)
    queue:push(event, strategy)
    return queue
end

function Map_MapQueue.next(world)
    local queue = ensureQueue(world)
    return queue:next()
end

function Map_MapQueue.isEmpty(world)
    if not world.mapQueue then
        return true
    end
    return world.mapQueue:isEmpty()
end

function Map_MapQueue.clear(world)
    if world.mapQueue then
        world.mapQueue:clear()
    end
end

return Map_MapQueue
