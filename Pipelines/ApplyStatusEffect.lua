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

    local displayName = target.name or target.id or "Target"

    local function addStatus(key, delta)
        target.status[key] = (target.status[key] or 0) + delta
        return target.status[key]
    end

    local function setMaxStatus(key, value)
        local current = target.status[key] or 0
        if value > current then
            target.status[key] = value
        end
        return target.status[key]
    end

    if effectType == "Poison" then
        local total = addStatus("poison", amount)
        table.insert(world.log, displayName .. " gained " .. amount .. " poison (" .. total .. ")")

    elseif effectType == "Vulnerable" then
        local total = addStatus("vulnerable", amount)
        table.insert(world.log, displayName .. " gained " .. amount .. " vulnerable (" .. total .. ")")

    elseif effectType == "Weak" then
        local total = addStatus("weak", amount)
        table.insert(world.log, displayName .. " gained " .. amount .. " weak (" .. total .. ")")

    elseif effectType == "Frail" then
        local total = addStatus("frail", amount)
        table.insert(world.log, displayName .. " gained " .. amount .. " frail (" .. total .. ")")

    elseif effectType == "Strength" then
        local total = addStatus("strength", amount)
        table.insert(world.log, displayName .. " strength changed by " .. amount .. " (" .. total .. ")")

    elseif effectType == "Strength Down" then
        local total = addStatus("strength", -amount)
        table.insert(world.log, displayName .. " lost " .. amount .. " strength (" .. total .. ")")

    elseif effectType == "Dexterity" then
        local total = addStatus("dexterity", amount)
        table.insert(world.log, displayName .. " dexterity changed by " .. amount .. " (" .. total .. ")")

    elseif effectType == "Dexterity Down" then
        local total = addStatus("dexterity", -amount)
        table.insert(world.log, displayName .. " lost " .. amount .. " dexterity (" .. total .. ")")

    elseif effectType == "Focus" then
        local total = addStatus("focus", amount)
        table.insert(world.log, displayName .. " focus changed by " .. amount .. " (" .. total .. ")")

    elseif effectType == "Focus Down" then
        local total = addStatus("focus", -amount)
        table.insert(world.log, displayName .. " lost " .. amount .. " focus (" .. total .. ")")

    elseif effectType == "Thorns" then
        local total = addStatus("thorns", amount)
        table.insert(world.log, displayName .. " gained " .. amount .. " thorns (" .. total .. ")")

    elseif effectType == "Confused" then
        local total = setMaxStatus("confused", amount)
        table.insert(world.log, displayName .. " became Confused (" .. total .. ")")

    elseif effectType == "No Draw" then
        local total = setMaxStatus("no_draw", amount)
        table.insert(world.log, displayName .. " cannot draw cards (" .. total .. ")")

    elseif effectType == "Block Return" then
        local total = addStatus("block_return", amount)
        table.insert(world.log, displayName .. " was afflicted with Block Return (" .. total .. ")")

    elseif effectType == "Shackled" then
        local total = addStatus("shackled", amount)
        table.insert(world.log, displayName .. " became Shackled (" .. total .. ")")

    elseif effectType == "Slow" then
        local total = addStatus("slow", amount)
        table.insert(world.log, displayName .. "'s Slow increased to " .. total)

    elseif effectType == "Draw Reduction" then
        local total = addStatus("draw_reduction", amount)
        table.insert(world.log, displayName .. "'s draws reduced (" .. total .. ")")

    elseif effectType == "No Block" then
        local total = setMaxStatus("no_block", amount)
        table.insert(world.log, displayName .. " cannot gain block (" .. total .. ")")

    elseif effectType == "Constricted" then
        local total = addStatus("constricted", amount)
        table.insert(world.log, displayName .. " is constricted (" .. total .. ")")

    elseif effectType == "Corpse Explosion" then
        local total = setMaxStatus("corpse_explosion", amount)
        table.insert(world.log, displayName .. " is primed to explode (" .. total .. ")")

    elseif effectType == "Choked" then
        local total = setMaxStatus("choked", amount)
        table.insert(world.log, displayName .. " is Choked (" .. total .. ")")

    elseif effectType == "Bias" then
        local total = addStatus("bias", amount)
        table.insert(world.log, displayName .. " is affected by Bias (" .. total .. ")")

    elseif effectType == "Hex" then
        local total = setMaxStatus("hex", amount)
        table.insert(world.log, displayName .. " is Hexed (" .. total .. ")")

    elseif effectType == "Lock-On" then
        local total = addStatus("lock_on", amount)
        table.insert(world.log, displayName .. " is targeted by Lock-On (" .. total .. ")")

    elseif effectType == "Mark" then
        local total = addStatus("mark", amount)
        table.insert(world.log, displayName .. " gained " .. amount .. " Mark (" .. total .. ")")

    elseif effectType == "Fasting" then
        local total = addStatus("fasting", amount)
        table.insert(world.log, displayName .. " is weakened by Fasting (" .. total .. ")")

    elseif effectType == "Wraith Form" then
        local total = addStatus("wraith_form", amount)
        table.insert(world.log, displayName .. " is in Wraith Form (" .. total .. ")")

    else
        table.insert(world.log, "Unknown status effect: " .. tostring(effectType))
    end
end

return ApplyStatusEffect
