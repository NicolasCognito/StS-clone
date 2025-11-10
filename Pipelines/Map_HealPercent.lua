-- MAP HEAL PERCENT PIPELINE
-- Restores a percentage of the player's max HP outside combat.

local Map_HealPercent = {}

local function clamp(value, low, high)
    if value < low then
        return low
    end
    if value > high then
        return high
    end
    return value
end

function Map_HealPercent.execute(world, percent)
    if not world or not world.player or not world.player.maxHp then
        return 0
    end

    percent = percent or 0
    local amount = math.floor(world.player.maxHp * percent + 0.5)

    if amount <= 0 then
        return 0
    end

    local before = world.player.currentHp or world.player.maxHp
    local after = clamp(before + amount, 0, world.player.maxHp)
    world.player.currentHp = after
    world.player.hp = after -- keep hp/currentHp in sync outside combat

    if world.log then
        table.insert(world.log, string.format("Healed %d HP (%d -> %d)", after - before, before, after))
    else
        print(string.format("Healed %d HP (%d -> %d)", after - before, before, after))
    end

    return after - before
end

return Map_HealPercent
