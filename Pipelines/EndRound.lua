-- END ROUND PIPELINE
-- world: the complete game state
-- player: the player character
-- enemies: list of all enemies
--
-- Handles:
-- - Remove block (unless Barricade is active)
-- - Tick down "End of Round" status effects for ALL combatants
-- - These effects trigger after ALL enemies have taken their turns
-- - Before the new player turn starts
--
-- Uses data-driven approach from statuseffects.lua (goesDownOnRoundEnd, roundEndMode)
-- Special behaviors are curated in SpecialBehaviors list
--
-- ARCHITECTURAL NOTE: This pattern trades ordering control for maintainability.
-- Using pairs() to iterate StatusEffects means execution order is non-deterministic.
-- We could restore ordering by:
--   1. Maintaining an explicit ordered list of status keys to process
--   2. Moving order-sensitive cases to SpecialBehaviors (above/below default route)
-- In this specific case, status tick-down order doesn't affect game state, so no issue.

local EndRound = {}

local StatusEffects = require("Data.statuseffects")

-- Curated list of special behaviors requiring explicit logic
local SpecialBehaviors = {"BLOCK"}

local function processRoundEndForCombatant(world, combatant, displayName)
    -- SPECIAL BEHAVIORS (curated list)

    -- BLOCK: Remove unless Barricade is active
    if combatant.block and combatant.block > 0 then
        if combatant.status and combatant.status.barricade and combatant.status.barricade > 0 then
            table.insert(world.log, displayName .. "'s Block retained (Barricade)")
        else
            combatant.block = 0
            table.insert(world.log, displayName .. "'s Block removed")
        end
    end

    -- DEFAULT ROUTE: Process all status effects from statuseffects.lua
    if not combatant.status then return end

    for statusKey, statusDef in pairs(StatusEffects) do
        -- Skip if in SpecialBehaviors list
        local isSpecial = false
        for _, specialKey in ipairs(SpecialBehaviors) do
            if specialKey:upper() == statusKey:upper() then
                isSpecial = true
                break
            end
        end

        if not isSpecial and statusDef.goesDownOnRoundEnd then
            local currentValue = combatant.status[statusKey]
            if currentValue and currentValue > 0 then
                if statusDef.roundEndMode == "TickDown" then
                    combatant.status[statusKey] = currentValue - 1
                    table.insert(world.log, displayName .. "'s " .. statusDef.name .. " decreased to " .. combatant.status[statusKey])
                elseif statusDef.roundEndMode == "WoreOff" then
                    combatant.status[statusKey] = nil
                    table.insert(world.log, displayName .. "'s " .. statusDef.name .. " wore off")
                end
            end
        end
    end
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
