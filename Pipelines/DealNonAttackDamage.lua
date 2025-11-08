-- DEAL NON-ATTACK DAMAGE PIPELINE
-- Processes ON_NON_ATTACK_DAMAGE events from the queue
--
-- Event should have:
-- - source: character dealing damage (can be nil for Thorns/Poison)
-- - target: character taking damage
-- - amount: raw damage amount
--
-- Handles:
-- - Raw damage without modifiers
-- - NO Strength scaling
-- - NO Vulnerable multiplier
-- - Block absorption
-- - HP reduction
-- - Combat logging
--
-- Used for: Thorns, Poison, other non-attack damage sources

local DealNonAttackDamage = {}

function DealNonAttackDamage.execute(world, event)
    local source = event.source
    local target = event.target
    local damage = event.amount or 0

    -- Apply block absorption
    local blockAbsorbed = math.min(target.block, damage)
    target.block = target.block - blockAbsorbed
    damage = damage - blockAbsorbed

    -- Apply remaining damage to HP
    target.hp = target.hp - damage

    -- Log
    local sourceName = source and source.name or "Effect"
    local logMsg = sourceName .. " dealt " .. damage .. " non-attack damage to " .. target.name
    if blockAbsorbed > 0 then
        logMsg = logMsg .. " (blocked " .. blockAbsorbed .. ")"
    end
    table.insert(world.log, logMsg)
end

return DealNonAttackDamage
