-- DEAL DAMAGE PIPELINE
-- Processes ON_DAMAGE events from the queue
--
-- Event should have:
-- - attacker: character dealing damage
-- - defender: character taking damage
-- - card: the card/source with damage value and scaling flags
-- - tags: optional array of tags (e.g., ["ignoreBlock"])
--
-- Handles:
-- - Base damage from card.damage
-- - Attacker's Strength multiplier (when added)
-- - Defender's Vulnerable/Weak modifiers (when added)
-- - Block absorption (unless "ignoreBlock" tag is present)
-- - HP reduction
-- - Combat logging

local DealDamage = {}

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

function DealDamage.execute(world, event)
    local attacker = event.attacker
    local defender = event.defender
    local card = event.card
    local tags = event.tags or {}

    -- Start with base damage
    local damage = card.damage or 0

    -- Apply strength multiplier if card has it and attacker has strength
    if card.strengthMultiplier and attacker.strength then
        damage = damage + (attacker.strength * card.strengthMultiplier)
    end

    -- Apply Vulnerable: 50% more damage (75% with Paper Phrog, rounded down)
    if defender.status and defender.status.vulnerable and defender.status.vulnerable > 0 then
        local vulnerableMultiplier = 1.5  -- default 50%

        -- Check if attacker has Paper Phrog relic
        if attacker.relics then
            for _, relic in ipairs(attacker.relics) do
                if relic.id == "Paper_Phrog" then
                    vulnerableMultiplier = 1.75  -- Paper Phrog: 75%
                    break
                end
            end
        end

        damage = math.floor(damage * vulnerableMultiplier)
    end

    local blockAbsorbed = 0

    -- Check if this damage ignores block
    if not hasTag(tags, "ignoreBlock") then
        -- Apply block absorption
        blockAbsorbed = math.min(defender.block, damage)
        defender.block = defender.block - blockAbsorbed
        damage = damage - blockAbsorbed
    end

    -- Apply remaining damage to HP
    defender.hp = defender.hp - damage

    -- Log
    local logMsg = attacker.name .. " dealt " .. damage .. " damage to " .. defender.name
    if blockAbsorbed > 0 then
        logMsg = logMsg .. " (blocked " .. blockAbsorbed .. ")"
    end
    table.insert(world.log, logMsg)

    -- Trigger Thorns counter-damage (if defender has Thorns status)
    -- Thorns triggers on any attack, even if fully blocked
    -- Thorns damage can be blocked (use ignoreBlock tag for HP loss effects like Bloodletting)
    if defender.status and defender.status.thorns and defender.status.thorns > 0 then
        world.queue:push({
            type = "ON_NON_ATTACK_DAMAGE",
            source = defender,
            target = attacker,
            amount = defender.status.thorns
            -- No tags - Thorns respects block
        })
    end
end

return DealDamage
