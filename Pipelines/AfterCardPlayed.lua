-- AFTER CARD PLAYED PIPELINE
-- Called after a card's onPlay effect has been executed
-- Used for cleanup actions that need to happen after card effects
--
-- Handles:
-- - Pen Nib counter reset (when counter reaches trigger threshold)

local AfterCardPlayed = {}

local Utils = require("utils")

function AfterCardPlayed.execute(world, player)
    if not player then
        return
    end

    -- Reset Pen Nib counter if it has reached trigger threshold
    local penNib = Utils.getRelic(player, "Pen_Nib")
    if penNib and world.penNibCounter >= penNib.triggerCount then
        world.penNibCounter = 0
        table.insert(world.log, "Pen Nib reset!")
    end

    local function queueChokedDamage(target)
        local stacks = (target.status and target.status.choked) or 0
        if stacks > 0 then
            local displayName = target.name or target.id or "Target"
            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = player,
                target = target,
                amount = stacks,
                tags = {"ignoreBlock"}
            })
            table.insert(world.log, displayName .. " took " .. stacks .. " damage from Choked")
        end
    end

    queueChokedDamage(player)

    if world.enemies then
        for _, enemy in ipairs(world.enemies) do
            if enemy.hp > 0 then
                queueChokedDamage(enemy)
            end
        end
    end
end

return AfterCardPlayed
