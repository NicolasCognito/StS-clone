-- RESOLVE CARD PIPELINE
-- Pops the next scheduled card execution from the card queue and resolves it.

local ResolveCard = {}

local PlayCard = require("Pipelines.PlayCard")

function ResolveCard.execute(world)
    if not world or not world.cardQueue or world.cardQueue:isEmpty() then
        return nil
    end

    local entry = world.cardQueue:pop()
    if not entry then
        return nil
    end

    -- Handle separator entries
    if entry.type == "SEPARATOR" then
        table.insert(world.log, "--- New Card ---")

        -- Clear stable context when transitioning between different cards
        -- (tempContext is indexed and doesn't need manual clearing)
        if world.combat then
            world.combat.stableContext = nil
        end

        -- Continue to next entry if queue isn't empty
        if not world.cardQueue:isEmpty() then
            return ResolveCard.execute(world)
        end
        return nil
    end

    return PlayCard.resolveQueuedEntry(world, entry)
end

return ResolveCard
