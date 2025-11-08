-- EVENT QUEUE
-- Simple queue for game events
-- Verbs push events here, ProcessEffectQueue drains it

local EventQueue = {}

function EventQueue.new()
    return {
        events = {}
    }
end

function EventQueue.push(queue, event)
    -- event should be a table with at least 'type' field
    table.insert(queue.events, event)
end

function EventQueue.isEmpty(queue)
    return #queue.events == 0
end

function EventQueue.next(queue)
    if EventQueue.isEmpty(queue) then
        return nil
    end
    return table.remove(queue.events, 1)
end

function EventQueue.clear(queue)
    queue.events = {}
end

return EventQueue
