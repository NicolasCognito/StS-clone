-- DEAL NON-ATTACK DAMAGE PIPELINE
-- Processes ON_NON_ATTACK_DAMAGE events from the queue
--
-- Event should have:
-- - source: character dealing damage (can be nil for Thorns/Poison)
-- - target: character taking damage OR "all" for all enemies
-- - amount: raw damage amount
-- - tags: optional array of tags (e.g., ["ignoreBlock"])
--
-- Handles:
-- - Raw damage without modifiers
-- - NO Strength scaling
-- - NO Vulnerable multiplier
-- - Block absorption (unless "ignoreBlock" tag is present)
-- - HP reduction
-- - Combat logging
-- - AOE damage (target = "all")
--
-- Used for: Thorns, Poison, other non-attack damage sources

local DealNonAttackDamage = {}

local Utils = require("utils")

function DealNonAttackDamage.execute(world, event)
    local source = event.source
    local target = event.target
    local damage = event.amount or 0
    local tags = event.tags or {}

    -- Handle AOE: target = "all" means hit all enemies
    if target == "all" then
        -- Add "aoe" tag so relics/powers can detect AOE effects
        local aoeTags = {}
        for _, tag in ipairs(tags) do
            table.insert(aoeTags, tag)
        end
        table.insert(aoeTags, "aoe")

        if world.enemies then
            for _, enemy in ipairs(world.enemies) do
                if enemy.hp > 0 then
                    -- Call with aoe tag added
                    DealNonAttackDamage.executeSingle(world, source, enemy, damage, aoeTags)
                end
            end
        end
        return
    end

    -- Single target damage
    DealNonAttackDamage.executeSingle(world, source, target, damage, tags)
end

-- Execute non-attack damage against a single target
function DealNonAttackDamage.executeSingle(world, source, target, damage, tags)
    -- Safety check: Skip if target is invalid or already dead
    if not target or not target.hp or target.hp <= 0 then
        table.insert(world.log, "Non-attack damage skipped - target no longer valid")
        return
    end

    -- Apply Tungsten Rod: Reduce all incoming damage by 1 (minimum 0)
    -- Applied before block absorption
    local tungstenRod = Utils.getRelic(target, "Tungsten_Rod")
    if tungstenRod and damage > 0 then
        damage = math.max(0, damage - tungstenRod.damageReduction)
    end

    -- Apply Invincible: Cap damage to remaining invincible value
    -- Applied after Tungsten Rod but before block absorption
    local targetStatus = target.status or {}
    if targetStatus.invincible and targetStatus.invincible > 0 and damage > 0 then
        local cappedDamage = math.min(damage, targetStatus.invincible)
        if cappedDamage < damage then
            local targetName = target.name or target.id or "Unknown"
            table.insert(world.log, targetName .. "'s Invincible capped damage from " .. damage .. " to " .. cappedDamage)
        end
        damage = cappedDamage
    end

    local blockAbsorbed = 0

    -- Check if this damage ignores block
    if not Utils.hasTag(tags, "ignoreBlock") then
        -- Apply block absorption
        blockAbsorbed = math.min(target.block, damage)
        target.block = target.block - blockAbsorbed
        damage = damage - blockAbsorbed
    end

    -- Apply remaining damage to HP
    target.hp = target.hp - damage

    -- Trigger onDmg relic hooks with full context
    Utils.triggerRelicHooks(world, world.player, "onDmg", {
        target = target,
        damage = damage,
        source = source,
        blockAbsorbed = blockAbsorbed
    })

    -- Reduce Invincible by damage dealt (after block absorption)
    -- Invincible caps total damage/HP loss per turn, not just pre-block damage
    if targetStatus.invincible and targetStatus.invincible > 0 and damage > 0 then
        targetStatus.invincible = targetStatus.invincible - damage
        -- Clamp to 0 minimum
        if targetStatus.invincible < 0 then
            targetStatus.invincible = 0
        end
    end

    -- Allow enemies to change intent on damage (e.g., Slime Boss splitting)
    if target.ChangeIntentOnDamage and damage > 0 then
        target.ChangeIntentOnDamage(target, world, source)
    end

    -- Track HP loss for Blood for Blood (only if player lost HP)
    if target == world.player and damage > 0 then
        world.combat.timesHpLost = world.combat.timesHpLost + 1
    end

    -- Log
    local sourceName = source and source.name or "Effect"
    local logMsg = sourceName .. " dealt " .. damage .. " non-attack damage to " .. target.name
    if blockAbsorbed > 0 then
        logMsg = logMsg .. " (blocked " .. blockAbsorbed .. ")"
    end
    table.insert(world.log, logMsg)

    -- Queue death event if target died (FIFO - added to front of queue)
    if target.hp <= 0 then
        world.queue:push({
            type = "ON_DEATH",
            entity = target,
            source = source,
            damage = damage + blockAbsorbed
        }, "FIRST")
    end
end

return DealNonAttackDamage
