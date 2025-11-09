-- APPLY CAPS PIPELINE
-- world: the complete game state
--
-- Handles:
-- - Enforce minimum and maximum values for all status effects
-- - Enforce HP caps (0 to character.maxHp)
-- - Enforce block cap (minimum 0, no maximum)
-- - Uses StatusEffects data for cap definitions
-- - Applies to ALL characters (player and all enemies)
--
-- Called directly by ProcessEffectQueue after each stat-modifying effect:
-- - After DealDamage
-- - After DealNonAttackDamage
-- - After ApplyBlock
-- - After ApplyStatusEffect
-- - After Heal

local ApplyCaps = {}

local StatusEffects = require("Data.StatusEffects.StatusEffects")

-- Apply caps to a single character
local function applyToCharacter(character)
    -- Apply caps to HP (0 to maxHp)
    if character.hp then
        character.hp = math.max(0, math.min(character.hp, character.maxHp))
    end

    -- Apply caps to block (minimum 0, no maximum)
    if character.block then
        character.block = math.max(0, character.block)
    end

    -- Apply caps to all status effects
    if character.status then
        for statusId, statusValue in pairs(character.status) do
            local statusDef = StatusEffects[statusId]
            if statusDef then
                -- Apply min/max from status definition
                local minValue = statusDef.minValue or 0
                local maxValue = statusDef.maxValue or 999

                character.status[statusId] = math.max(minValue, math.min(statusValue, maxValue))

                -- Remove status if it reaches 0 (cleanup)
                if character.status[statusId] == 0 and minValue >= 0 then
                    character.status[statusId] = nil
                end
            else
                -- Unknown status effect - still apply basic 0 floor
                character.status[statusId] = math.max(0, statusValue)
                if character.status[statusId] == 0 then
                    character.status[statusId] = nil
                end
            end
        end
    end
end

-- Main execute function - applies caps to all characters
function ApplyCaps.execute(world)
    -- Apply to player
    if world.player then
        applyToCharacter(world.player)
    end

    -- Apply to enemy (single enemy for now)
    if world.enemy then
        applyToCharacter(world.enemy)
    end

    -- TODO: When multiple enemies are supported, loop through all enemies
    -- if world.enemies then
    --     for _, enemy in ipairs(world.enemies) do
    --         applyToCharacter(enemy)
    --     end
    -- end
end

return ApplyCaps
