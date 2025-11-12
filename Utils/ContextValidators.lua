-- CONTEXT VALIDATORS
-- Helper functions for validating stable context before card resolution

local ContextValidators = {}

-- Validates that the specific enemy in context is still alive
-- Used for single-target cards (Strike, Bash, etc.)
-- Accepts: nil (allows re-collection) or living enemy
-- Rejects: dead enemy
function ContextValidators.specificEnemyAlive(world, context, card)
    if context == nil then
        return true  -- nil is valid, allows card to collect new context
    end
    return context.currentHealth and context.currentHealth > 0
end

-- Validates that at least one enemy is alive in combat
-- Used for AoE cards or cards that don't need a specific target
-- Accepts: nil (allows re-collection) or when any enemy is alive
-- Rejects: when all enemies are dead
function ContextValidators.anyEnemyAlive(world, context, card)
    if context == nil then
        return true  -- nil is valid, allows card to collect new context
    end

    -- Check if at least one enemy is alive in combat
    for _, enemy in ipairs(world.combat.enemies) do
        if enemy.currentHealth > 0 then
            return true
        end
    end
    return false
end

return ContextValidators
