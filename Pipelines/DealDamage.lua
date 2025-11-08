-- DEAL DAMAGE PIPELINE
-- world: the complete game state
-- attacker: character dealing damage
-- defender: character taking damage
-- card: the card being played (contains baseDamage and any scaling flags)
--
-- Handles:
-- - Base damage from card
-- - Attacker's Strength multiplier (when added)
-- - Defender's Vulnerable/Weak (when added)
-- - Block absorption
-- - HP reduction
-- - Combat log
-- - Pushes ON_DAMAGE event to queue

local DealDamage = {}

function DealDamage.execute(world, attacker, defender, card)
    -- TODO: implement
end

return DealDamage
