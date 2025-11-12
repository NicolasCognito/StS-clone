-- MAP RECEIVE DAMAGE PIPELINE
-- Applies damage to the player during map events (non-combat).
-- This is separate from combat damage and operates on world.player.currentHp.
--
-- Event should have:
-- - amount: damage amount (can be a function that returns a number)
-- - source: optional string describing the damage source
--
-- Features:
-- - Applies Tungsten Rod damage reduction if player has it
-- - Operates on currentHp (not combat hp)
-- - Keeps hp and currentHp in sync
-- - Minimum damage is 0 (no healing from negative amounts)
-- - Player can't go below 0 HP

local Map_ReceiveDamage = {}

local Utils = require("utils")

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

function Map_ReceiveDamage.execute(world, event)
    if not world or not world.player or not world.player.maxHp then
        return 0
    end

    local amount = resolveAmount(event)

    if amount <= 0 then
        return 0
    end

    -- Apply Tungsten Rod: Reduce all incoming damage by 1 (minimum 0)
    -- This mirrors the logic in DealNonAttackDamage.lua:63-68
    local tungstenRod = Utils.getRelic(world.player, "Tungsten_Rod")
    if tungstenRod and amount > 0 then
        local reduction = tungstenRod.damageReduction or 1
        amount = math.max(0, amount - reduction)

        if world.log then
            table.insert(world.log, string.format("Tungsten Rod reduced damage by %d", reduction))
        end
    end

    -- Apply damage to currentHp
    local before = world.player.currentHp or world.player.maxHp
    local after = clamp(before - amount, 0, world.player.maxHp)
    world.player.currentHp = after
    world.player.hp = after -- keep hp/currentHp in sync outside combat

    local actualDamage = before - after
    local sourceLabel = (event and event.source) or "Damage"
    local message = string.format("%s: Lost %d HP (%d -> %d)", sourceLabel, actualDamage, before, after)

    if world.log then
        table.insert(world.log, message)
    else
        print(message)
    end

    return actualDamage
end

return Map_ReceiveDamage
