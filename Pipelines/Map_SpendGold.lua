-- MAP SPEND GOLD PIPELINE
-- Deducts gold in the overworld context.

local Map_SpendGold = {}

function Map_SpendGold.execute(world, amount)
    if not world or not world.player then
        return 0
    end

    amount = math.max(0, math.floor(amount or 0))

    local before = world.player.gold or 0
    local after = math.max(0, before - amount)
    world.player.gold = after

    if world.log then
        table.insert(world.log, string.format("Spent %d gold (%d -> %d)", amount, before, after))
    else
        print(string.format("Spent %d gold (%d -> %d)", amount, before, after))
    end

    return before - after
end

return Map_SpendGold
