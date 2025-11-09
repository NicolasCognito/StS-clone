-- APPLY STATUS EFFECT PIPELINE
-- Processes ON_STATUS_GAIN events from the queue
--
-- Event should have:
-- - target: character gaining the status (or "all" for AOE)
-- - effectType: type of status (Poison, Vulnerable, Weak, Strength, etc.)
-- - amount: amount of the status effect
-- - source: what caused this effect (card, enemy, relic)
-- - tags: (optional) array of tags like "aoe"
--
-- Handles:
-- - Applying status effects to character(s)
-- - AOE status application when target = "all"
-- - Status-specific rules (caps, interactions, etc.)
-- - Combat logging

local ApplyStatusEffect = {}

function ApplyStatusEffect.execute(world, event)
    local target = event.target
    local effectType = event.effectType
    local amount = event.amount or 0
    local source = event.source
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
                    ApplyStatusEffect.executeSingle(world, enemy, effectType, amount, source, aoeTags)
                end
            end
        end
        return
    end

    -- Single target application
    ApplyStatusEffect.executeSingle(world, target, effectType, amount, source, tags)
end

function ApplyStatusEffect.executeSingle(world, target, effectType, amount, source, tags)
    -- Initialize status object if needed
    if not target.status then
        target.status = {}
    end

    -- Apply the status based on type
    if effectType == "Poison" then
        target.status.poison = (target.status.poison or 0) + amount
        table.insert(world.log, target.name .. " gained " .. amount .. " poison")

    elseif effectType == "Vulnerable" then
        target.status.vulnerable = (target.status.vulnerable or 0) + amount
        table.insert(world.log, target.name .. " gained " .. amount .. " vulnerable")

    elseif effectType == "Weak" then
        target.status.weak = (target.status.weak or 0) + amount
        table.insert(world.log, target.name .. " gained " .. amount .. " weak")

    elseif effectType == "Strength" then
        target.status.strength = (target.status.strength or 0) + amount
        table.insert(world.log, target.name .. " gained " .. amount .. " strength")

    elseif effectType == "Thorns" then
        target.status.thorns = (target.status.thorns or 0) + amount
        table.insert(world.log, target.name .. " gained " .. amount .. " thorns")

    else
        table.insert(world.log, "Unknown status effect: " .. effectType)
    end
end

return ApplyStatusEffect
