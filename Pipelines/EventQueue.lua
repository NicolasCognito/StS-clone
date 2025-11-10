-- EVENT QUEUE
-- Simple queue for game events
-- Verbs push events here, ProcessEffectQueue drains it

local EventQueue = {}
EventQueue.__index = EventQueue

function EventQueue.new()
    local queue = {
        events = {}
    }
    setmetatable(queue, EventQueue)
    return queue
end

function EventQueue:push(event, strategy)
    -- event should be a table with at least 'type' field
    -- strategy: optional "FIRST" or "LAST" (default: "LAST")
    -- LAST: add to end of queue
    -- FIRST: add to beginning of queue
    strategy = strategy or "LAST"

    if strategy == "FIRST" then
        table.insert(self.events, 1, event)
    else
        table.insert(self.events, event)
    end
end

function EventQueue:isEmpty()
    return #self.events == 0
end

function EventQueue:next()
    if self:isEmpty() then
        return nil
    end
    return table.remove(self.events, 1)
end

function EventQueue:clear()
    self.events = {}
end

return EventQueue
