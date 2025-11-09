-- DEAL NON-ATTACK DAMAGE PIPELINE
-- Processes ON_NON_ATTACK_DAMAGE events from the queue
--
-- Event should have:
-- - source: character dealing damage (can be nil for Thorns/Poison)
-- - target: character taking damage
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
--
-- Used for: Thorns, Poison, other non-attack damage sources

local DealNonAttackDamage = {}

-- Helper function to check if a tag exists in the tags array
local function hasTag(tags, tagName)
    if not tags then return false end
    for _, tag in ipairs(tags) do
        if tag == tagName then
            return true
        end
    end
    return false
end

function DealNonAttackDamage.execute(world, event)
    local source = event.source
    local target = event.target
    local damage = event.amount or 0
    local tags = event.tags or {}

    local blockAbsorbed = 0

    -- Check if this damage ignores block
    if not hasTag(tags, "ignoreBlock") then
        -- Apply block absorption
        blockAbsorbed = math.min(target.block, damage)
        target.block = target.block - blockAbsorbed
        damage = damage - blockAbsorbed
    end

    -- Apply remaining damage to HP
    target.hp = target.hp - damage

    -- Apply caps to target (HP, block, status effects)
    world.queue:push({
        type = "ON_APPLY_CAPS",
        character = target
    })

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
end

return DealNonAttackDamage
