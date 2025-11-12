-- CARD QUEUE
-- LIFO queue used to schedule card executions (initial play + duplications)
-- Entries are simple tables describing what should be resolved next.

local CardQueue = {}
CardQueue.__index = CardQueue

function CardQueue.new()
    return setmetatable({
        entries = {}
    }, CardQueue)
end

function CardQueue:isEmpty()
    return #self.entries == 0
end

function CardQueue:push(entry)
    table.insert(self.entries, entry)
end

function CardQueue:pop()
    if self:isEmpty() then
        return nil
    end
    return table.remove(self.entries)
end

function CardQueue:clear()
    self.entries = {}
end

-- Push a separator to visually mark the boundary between different card runs
function CardQueue:pushSeparator()
    table.insert(self.entries, {
        type = "SEPARATOR"
    })
end

return CardQueue
