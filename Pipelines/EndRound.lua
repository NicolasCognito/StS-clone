-- END ROUND PIPELINE
-- world: the complete game state
-- player: the player character
-- enemies: list of all enemies
--
-- Handles:
-- - Tick down "End of Round" status effects for ALL combatants
-- - These effects trigger after ALL enemies have taken their turns
-- - Before the new player turn starts
--
-- End of Round effects (from Slay the Spire mechanics):
-- - vulnerable, weak, frail: decrease by 1
-- - blur: wear off (set to 0)
-- - intangible (player version): decrease by 1
--
-- This is different from "End of Turn" effects which trigger at the end
-- of each individual character's turn.

local EndRound = {}

function EndRound.execute(world, player, enemies)
    table.insert(world.log, "--- End of Round ---")

    -- Tick down player's end-of-round status effects
    if player.status then
        -- Vulnerable
        if player.status.vulnerable and player.status.vulnerable > 0 then
            player.status.vulnerable = player.status.vulnerable - 1
            table.insert(world.log, player.id .. "'s Vulnerable decreased to " .. player.status.vulnerable)
        end

        -- Weak
        if player.status.weak and player.status.weak > 0 then
            player.status.weak = player.status.weak - 1
            table.insert(world.log, player.id .. "'s Weak decreased to " .. player.status.weak)
        end

        -- Frail
        if player.status.frail and player.status.frail > 0 then
            player.status.frail = player.status.frail - 1
            table.insert(world.log, player.id .. "'s Frail decreased to " .. player.status.frail)
        end

        -- Blur (wears off at end of round)
        if player.status.blur and player.status.blur > 0 then
            player.status.blur = 0
            table.insert(world.log, player.id .. "'s Blur wore off")
        end

        -- Intangible (player version - decreases at end of round)
        if player.status.intangible and player.status.intangible > 0 then
            player.status.intangible = player.status.intangible - 1
            table.insert(world.log, player.id .. "'s Intangible decreased to " .. player.status.intangible)
        end
    end

    -- Tick down enemies' end-of-round status effects
    if enemies then
        for _, enemy in ipairs(enemies) do
            if enemy.hp > 0 and enemy.status then
                -- Vulnerable
                if enemy.status.vulnerable and enemy.status.vulnerable > 0 then
                    enemy.status.vulnerable = enemy.status.vulnerable - 1
                    table.insert(world.log, enemy.name .. "'s Vulnerable decreased to " .. enemy.status.vulnerable)
                end

                -- Weak
                if enemy.status.weak and enemy.status.weak > 0 then
                    enemy.status.weak = enemy.status.weak - 1
                    table.insert(world.log, enemy.name .. "'s Weak decreased to " .. enemy.status.weak)
                end

                -- Frail
                if enemy.status.frail and enemy.status.frail > 0 then
                    enemy.status.frail = enemy.status.frail - 1
                    table.insert(world.log, enemy.name .. "'s Frail decreased to " .. enemy.status.frail)
                end

                -- Intangible (enemy version - decreases at end of round)
                if enemy.status.intangible and enemy.status.intangible > 0 then
                    enemy.status.intangible = enemy.status.intangible - 1
                    table.insert(world.log, enemy.name .. "'s Intangible decreased to " .. enemy.status.intangible)
                end
            end
        end
    end
end

return EndRound
