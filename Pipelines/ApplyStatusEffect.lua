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
-- - Artifact blocking (debuffs and negative stat changes)
-- - Applying status effects to character(s)
-- - AOE status application when target = "all"
-- - Status-specific rules (caps, interactions, etc.)
-- - Combat logging
--
-- Uses data-driven approach from statuseffects.lua
-- Special behaviors are curated in SpecialBehaviors list
--
-- ARCHITECTURAL NOTE: This pattern separates special logic from default behavior.
-- SpecialBehaviors list contains effects needing custom handling (e.g., "Strength Down").
-- All other effects route through statuseffects.lua lookup with generic application.
-- If order-sensitive interactions emerge, move them to SpecialBehaviors (curated list).

local ApplyStatusEffect = {}

local StatusEffects = require("Data.statuseffects")

-- Curated list of special behaviors requiring explicit logic
local SpecialBehaviors = {"Strength Down", "Dexterity Down", "Focus Down"}

-- Check if effect is blocked by Artifact
local function isBlockedByArtifact(target, effectType, amount)
    if not target.status or not target.status.artifact or target.status.artifact <= 0 then
        return false
    end

    -- Block debuffs
    local statusDef = StatusEffects[effectType:lower():gsub(" ", "_")]
    if statusDef and statusDef.debuff then
        return true
    end

    -- Block negative stat changes
    if effectType == "Strength Down" or effectType == "Dexterity Down" or effectType == "Focus Down" then
        return true
    end

    -- Also block if it's a stat decrease (negative amount to positive stat)
    if (effectType == "Strength" or effectType == "Dexterity" or effectType == "Focus") and amount < 0 then
        return true
    end

    return false
end

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
    -- Don't apply status to dead targets
    if target.dead or (target.hp and target.hp <= 0) then
        return
    end

    -- Initialize status object if needed
    if not target.status then
        target.status = {}
    end

    local displayName = target.name or target.id or "Target"

    -- Check Artifact blocking
    if isBlockedByArtifact(target, effectType, amount) then
        target.status.artifact = target.status.artifact - 1
        table.insert(world.log, displayName .. "'s Artifact blocked " .. effectType)
        return
    end

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

    -- SPECIAL BEHAVIORS (curated list)

    if effectType == "Strength Down" then
        local total = addStatus("strength", -amount)
        table.insert(world.log, displayName .. " lost " .. amount .. " strength (" .. total .. ")")

    elseif effectType == "Dexterity Down" then
        local total = addStatus("dexterity", -amount)
        table.insert(world.log, displayName .. " lost " .. amount .. " dexterity (" .. total .. ")")

    elseif effectType == "Focus Down" then
        local total = addStatus("focus", -amount)
        table.insert(world.log, displayName .. " lost " .. amount .. " focus (" .. total .. ")")

    else
        -- DEFAULT ROUTE: Look up in statuseffects.lua
        local statusKey = effectType:lower():gsub(" ", "_")
        local statusDef = StatusEffects[statusKey]

        if statusDef then
            -- Determine application mode from definition or infer from old behavior
            local applicationMode = statusDef.applicationMode or "add"

            -- Infer from known max-based statuses if not specified
            if not statusDef.applicationMode then
                if statusKey == "confused" or statusKey == "no_draw" or statusKey == "no_block" or
                   statusKey == "corpse_explosion" or statusKey == "choked" or statusKey == "hex" then
                    applicationMode = "max"
                end
            end

            local total
            if applicationMode == "max" then
                total = setMaxStatus(statusKey, amount)
            else
                total = addStatus(statusKey, amount)
            end

            table.insert(world.log, displayName .. " gained " .. amount .. " " .. statusDef.name .. " (" .. total .. ")")

            -- MANTRA SPECIAL TRIGGER: Check for Divinity at 10+ Mantra
            if statusKey == "mantra" and target.status.mantra >= 10 then
                -- Track total Mantra gained for Brilliance card
                if world.combat then
                    world.combat.mantraGainedThisCombat = (world.combat.mantraGainedThisCombat or 0) + amount
                end

                -- Reduce by 10 and enter Divinity
                target.status.mantra = target.status.mantra - 10
                table.insert(world.log, displayName .. " gained 10 Mantra - entering Divinity!")

                -- Push ChangeStance with FIRST priority (immediate trigger)
                world.queue:push({
                    type = "CHANGE_STANCE",
                    newStance = "Divinity"
                }, "FIRST")
            elseif statusKey == "mantra" then
                -- Track Mantra gains even if not triggering Divinity
                if world.combat then
                    world.combat.mantraGainedThisCombat = (world.combat.mantraGainedThisCombat or 0) + amount
                end
            end
        else
            table.insert(world.log, "Unknown status effect: " .. tostring(effectType))
        end
    end
end

return ApplyStatusEffect
