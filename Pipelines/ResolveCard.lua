-- RESOLVE CARD PIPELINE
-- Pops the next scheduled card execution from the card queue and resolves it.
-- Note: Autocasting (Mayhem, Distilled Chaos) is now handled by Autocast pipeline

local ResolveCard = {}

local PlayCard = require("Pipelines.PlayCard")

function ResolveCard.execute(world)
    if not world or not world.cardQueue then
        return nil
    end

    -- Return if queue is empty
    if world.cardQueue:isEmpty() then
        return nil
    end

    local entry = world.cardQueue:pop()
    if not entry then
        return nil
    end

    -- Handle separator entries
    if entry.type == "SEPARATOR" then
        table.insert(world.log, "--- New Card ---")

        -- Clear context when transitioning between different cards
        if world.combat then
            world.combat.stableContext = nil
            world.combat.tempContext = nil
        end

        -- Continue processing (check queue or autocasting)
        return ResolveCard.execute(world)
    end

    return PlayCard.resolveQueuedEntry(world, entry)
end

return ResolveCard
