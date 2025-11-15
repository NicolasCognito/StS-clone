-- AFTER CARD PLAYED PIPELINE
-- Called after a card's onPlay effect has been executed
-- Used for cleanup actions that need to happen after card effects
--
-- Handles:
-- - Pen Nib counter reset (when counter reaches trigger threshold)
-- - Choked status damage
-- - cardsPlayedThisTurn tracking (stores metadata for each card played)
-- - Panache trigger (every 5th card deals damage to all enemies)
-- - Card play limit tracking and enforcement (Velvet Choker, Normality)

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

    -- Store card metadata in cardsPlayedThisTurn table
    -- This updates after EVERY card execution (including duplications)
    if world.combat and world.combat.currentExecutingCard then
        table.insert(world.combat.cardsPlayedThisTurn, {
            type = world.combat.currentExecutingCard.type,
            name = world.combat.currentExecutingCard.name,
            id = world.combat.currentExecutingCard.id
        })

        -- Check for Panache trigger (every 5th card)
        if Utils.hasPower(player, "Panache") then
            local panacheDamage = player.status.panache or 0
            if #world.combat.cardsPlayedThisTurn % 5 == 0 then
                -- Deal damage to all enemies
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = player,
                    defender = "all",
                    amount = panacheDamage,
                    card = nil  -- No card associated with Panache trigger
                })
                table.insert(world.log, "Panache! Dealt " .. panacheDamage .. " damage to all enemies")
            end
        end

        -- Enforce card play limits (Velvet Choker, Normality)
        -- Recalculate limit (Normality might have been played/exhausted this execution!)
        local limit = Utils.getCardPlayLimit(world, player)

        -- Check if we've exceeded the limit
        if #world.combat.cardsPlayedThisTurn > limit and world.cardQueue and not world.cardQueue:isEmpty() then
            -- Abort all pending duplications
            world.cardQueue:clear()
            table.insert(world.log, "Card play limit (" .. limit .. ") exceeded - aborting duplications")
        end
    end
end

return AfterCardPlayed
