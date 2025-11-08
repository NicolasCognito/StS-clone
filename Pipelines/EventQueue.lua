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

function EventQueue:push(event)
    -- event should be a table with at least 'type' field
    table.insert(self.events, event)
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
