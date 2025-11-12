-- ORB PASSIVE PIPELINE
-- Triggers passive effects of all orbs
--
-- Called from EndTurn.lua BEFORE discarding hand
--
-- Handles:
-- - Lightning passive: Deal damage to random enemy (scales with Focus)
-- - Frost passive: Gain block (scales with Focus)
-- - Dark passive: Accumulate damage (scales with Focus)
-- - Plasma passive: None (Plasma has no passive effect)
--
-- Passive values are calculated here using current Focus status

local OrbPassive = {}

local Utils = require("utils")

function OrbPassive.execute(world)
    local player = world.player

    -- Trigger passive for each orb left to right
    for i, orb in ipairs(player.orbs) do
        OrbPassive.executeSingle(world, orb)
    end
end

-- Execute passive effect for a single orb
function OrbPassive.executeSingle(world, orb)
    local player = world.player
    local focus = (player.status and player.status.focus) or 0

    if orb.id == "Lightning" then
        -- Lightning passive: Deal damage to random enemy (scales with Focus)
        local passiveDamage = (orb.basePassive or 3) + focus
        passiveDamage = math.max(0, passiveDamage)

        local target = Utils.randomEnemy(world)
        if target then
            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = player,
                target = target,
                amount = passiveDamage
            })
        end

    elseif orb.id == "Frost" then
        -- Frost passive: Gain block (scales with Focus)
        local passiveBlock = (orb.basePassive or 2) + focus
        passiveBlock = math.max(0, passiveBlock)

        world.queue:push({
            type = "ON_BLOCK",
            target = player,
            amount = passiveBlock
        })

    elseif orb.id == "Dark" then
        -- Dark passive: Accumulate damage (scales with Focus)
        local increment = (orb.damageIncrement or 6) + focus
        increment = math.max(0, increment)

        orb.accumulatedDamage = orb.accumulatedDamage + increment
        table.insert(world.log, orb.id .. " gained " .. increment .. " damage (total: " .. orb.accumulatedDamage .. ")")

    -- Plasma has no passive effect
    end
end

return OrbPassive
