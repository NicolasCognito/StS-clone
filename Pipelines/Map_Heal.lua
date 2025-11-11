-- MAP HEAL PIPELINE
-- Applies a flat heal amount to the overworld player state.

local Map_Heal = {}

local function clamp(value, low, high)
    if value < low then
        return low
    end
    if value > high then
        return high
    end
    return value
end

local function resolveAmount(event)
    if not event then
        return 0
    end

    local amount = event.amount or 0

    if type(amount) == "function" then
        amount = amount()
    end

    if amount < 0 then
        return 0
    end

    return math.floor(amount)
end

function Map_Heal.execute(world, event)
    if not world or not world.player or not world.player.maxHp then
        return 0
    end

    local amount = resolveAmount(event)

    if amount <= 0 then
        return 0
    end

    local before = world.player.currentHp or world.player.maxHp
    local after = clamp(before + amount, 0, world.player.maxHp)
    world.player.currentHp = after
    world.player.hp = after -- keep hp/currentHp in sync outside combat

    local sourceLabel = (event and event.source) or "Heal"
    local message = string.format("%s: Healed %d HP (%d -> %d)", sourceLabel, after - before, before, after)

    if world.log then
        table.insert(world.log, message)
    else
        print(message)
    end

    return after - before
end

return Map_Heal
