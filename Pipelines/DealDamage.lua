-- DEAL DAMAGE PIPELINE
-- Processes ON_DAMAGE events from the queue
--
-- Event should have:
-- - attacker: character dealing damage
-- - defender: character taking damage
-- - card: the card/source with damage value and scaling flags
--
-- Handles:
-- - Base damage from card.damage
-- - Attacker's Strength multiplier (when added)
-- - Defender's Vulnerable/Weak modifiers (when added)
-- - Block absorption
-- - HP reduction
-- - Combat logging

local DealDamage = {}

function DealDamage.execute(world, event)
    local attacker = event.attacker
    local defender = event.defender
    local card = event.card

    -- Start with base damage
    local damage = card.damage or 0

    -- Apply strength multiplier if card has it and attacker has strength
    if card.strengthMultiplier and attacker.strength then
        damage = damage + (attacker.strength * card.strengthMultiplier)
    end

    -- Apply Vulnerable: 50% more damage (rounded down)
    if defender.status and defender.status.vulnerable and defender.status.vulnerable > 0 then
        damage = math.floor(damage * 1.5)
    end

    -- Apply block absorption
    local blockAbsorbed = math.min(defender.block, damage)
    defender.block = defender.block - blockAbsorbed
    damage = damage - blockAbsorbed

    -- Apply remaining damage to HP
    defender.hp = defender.hp - damage

    -- Log
    local logMsg = attacker.name .. " dealt " .. damage .. " damage to " .. defender.name
    if blockAbsorbed > 0 then
        logMsg = logMsg .. " (blocked " .. blockAbsorbed .. ")"
    end
    table.insert(world.log, logMsg)
end

return DealDamage
