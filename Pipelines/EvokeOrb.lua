-- EVOKE ORB PIPELINE
-- Processes ON_EVOKE_ORB events from the queue
--
-- Event should have:
-- - index: Index of orb to evoke (1 = leftmost) OR "all" to evoke all orbs
--
-- Handles:
-- - Lightning evoke: Deal damage to random enemy (scales with Focus)
-- - Frost evoke: Gain block (scales with Focus)
-- - Dark evoke: Deal accumulated damage to lowest HP enemy
-- - Plasma evoke: Gain energy (does NOT scale with Focus)
-- - Remove orb from player.orbs array
-- - Combat logging
--
-- Evoked damage/block is calculated here using current Focus status

local EvokeOrb = {}

local Utils = require("utils")

function EvokeOrb.execute(world, event)
    local player = world.player
    local index = event.index

    -- Handle "all" evokes (e.g., Meteor Strike card)
    if index == "all" then
        -- Evoke all orbs left to right
        for i = 1, #player.orbs do
            EvokeOrb.executeSingle(world, player.orbs[1])  -- Always evoke [1] as array shifts
            table.remove(player.orbs, 1)
        end
        return
    end

    -- Single evoke
    local orb = player.orbs[index]
    if not orb then
        return  -- No orb to evoke
    end

    EvokeOrb.executeSingle(world, orb)
    table.remove(player.orbs, index)
end

-- Execute evoke effect for a single orb
function EvokeOrb.executeSingle(world, orb)
    local player = world.player
    local focus = (player.status and player.status.focus) or 0

    table.insert(world.log, "Evoked " .. orb.id .. " orb")

    if orb.id == "Lightning" then
        -- Lightning evoke: Deal damage to random enemy (scales with Focus)
        local evokeDamage = (orb.baseDamage or 8) + focus
        evokeDamage = math.max(0, evokeDamage)

        local target = Utils.randomEnemy(world)
        if target then
            -- Apply Lock-On damage bonus (50% more damage)
            if target.status and target.status.lock_on and target.status.lock_on > 0 then
                evokeDamage = math.floor(evokeDamage * 1.5)
                table.insert(world.log, target.name .. " took enhanced damage from Lock-On")
            end

            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = player,
                target = target,
                amount = evokeDamage
            })
        end

    elseif orb.id == "Frost" then
        -- Frost evoke: Gain block (scales with Focus)
        local evokeBlock = (orb.baseBlock or 5) + focus
        evokeBlock = math.max(0, evokeBlock)

        world.queue:push({
            type = "ON_BLOCK",
            target = player,
            amount = evokeBlock
        })

    elseif orb.id == "Dark" then
        -- Dark evoke: Deal accumulated damage to lowest HP enemy
        local target = Utils.lowestHpEnemy(world)
        if target then
            local darkDamage = orb.accumulatedDamage

            -- Apply Lock-On damage bonus (50% more damage)
            if target.status and target.status.lock_on and target.status.lock_on > 0 then
                darkDamage = math.floor(darkDamage * 1.5)
                table.insert(world.log, target.name .. " took enhanced damage from Lock-On")
            end

            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = player,
                target = target,
                amount = darkDamage
            })
        end

    elseif orb.id == "Plasma" then
        -- Plasma evoke: Gain energy (does NOT scale with Focus)
        player.energy = player.energy + (orb.energyGain or 2)
        table.insert(world.log, player.name .. " gained " .. (orb.energyGain or 2) .. " energy")
    end
end

return EvokeOrb
