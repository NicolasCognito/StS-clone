-- END ROUND PIPELINE
-- world: the complete game state
-- player: the player character
-- enemies: list of all enemies
--
-- Handles:
-- - Remove block (unless Barricade is active)
-- - Trigger onEndRound hooks for ALL combatants
-- - These effects trigger after ALL enemies have taken their turns
-- - Before the new player turn starts
--
-- Status effects can have optional onEndRound hooks that are called here

local EndRound = {}

local StatusEffects = require("Data.statuseffects")

-- Helper: Call onEndRound hooks for all status effects on a combatant
local function triggerStatusHooks(world, combatant)
    if not combatant.status then return end

    for statusKey, statusDef in pairs(StatusEffects) do
        if statusDef.onEndRound and combatant.status[statusKey] and combatant.status[statusKey] > 0 then
            statusDef.onEndRound(world, combatant)
        end
    end
end

local function processRoundEndForCombatant(world, combatant, displayName)
    -- BLOCK: Remove unless Barricade is active
    if combatant.block and combatant.block > 0 then
        if combatant.status and combatant.status.barricade and combatant.status.barricade > 0 then
            table.insert(world.log, displayName .. "'s Block retained (Barricade)")
        else
            combatant.block = 0
            table.insert(world.log, displayName .. "'s Block removed")
        end
    end

    -- Trigger status effect hooks
    triggerStatusHooks(world, combatant)
end

function EndRound.execute(world, player, enemies)
    table.insert(world.log, "--- End of Round ---")

    -- Process player
    processRoundEndForCombatant(world, player, player.id)

    -- Process enemies
    if enemies then
        for _, enemy in ipairs(enemies) do
            if enemy.hp > 0 then
                processRoundEndForCombatant(world, enemy, enemy.name)
            end
        end
    end
end

return EndRound
