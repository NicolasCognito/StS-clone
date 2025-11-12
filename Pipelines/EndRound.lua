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

        if player.status.slow and player.status.slow > 0 then
            player.status.slow = nil
            table.insert(world.log, player.id .. "'s Slow reset")
        end

        if player.status.block_return and player.status.block_return > 0 then
            player.status.block_return = nil
            table.insert(world.log, player.id .. "'s Block Return wore off")
        end

        if player.status.draw_reduction and player.status.draw_reduction > 0 then
            player.status.draw_reduction = nil
            table.insert(world.log, player.id .. "'s Draw Reduction wore off")
        end

        if player.status.no_draw and player.status.no_draw > 0 then
            player.status.no_draw = player.status.no_draw - 1
            if player.status.no_draw <= 0 then
                player.status.no_draw = nil
                table.insert(world.log, player.id .. " can draw again next turn")
            else
                table.insert(world.log, player.id .. "'s No Draw decreased to " .. player.status.no_draw)
            end
        end

        if player.status.no_block and player.status.no_block > 0 then
            player.status.no_block = player.status.no_block - 1
            if player.status.no_block <= 0 then
                player.status.no_block = nil
                table.insert(world.log, player.id .. " can gain Block again")
            else
                table.insert(world.log, player.id .. "'s No Block decreased to " .. player.status.no_block)
            end
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

                if enemy.status.slow and enemy.status.slow > 0 then
                    enemy.status.slow = nil
                    table.insert(world.log, enemy.name .. "'s Slow reset")
                end

                if enemy.status.block_return and enemy.status.block_return > 0 then
                    enemy.status.block_return = nil
                    table.insert(world.log, enemy.name .. "'s Block Return wore off")
                end

                if enemy.status.draw_reduction and enemy.status.draw_reduction > 0 then
                    enemy.status.draw_reduction = nil
                    table.insert(world.log, enemy.name .. "'s Draw Reduction wore off")
                end

                if enemy.status.no_draw and enemy.status.no_draw > 0 then
                    enemy.status.no_draw = enemy.status.no_draw - 1
                    if enemy.status.no_draw <= 0 then
                        enemy.status.no_draw = nil
                        table.insert(world.log, enemy.name .. " can draw again next turn")
                    else
                        table.insert(world.log, enemy.name .. "'s No Draw decreased to " .. enemy.status.no_draw)
                    end
                end

                if enemy.status.no_block and enemy.status.no_block > 0 then
                    enemy.status.no_block = enemy.status.no_block - 1
                    if enemy.status.no_block <= 0 then
                        enemy.status.no_block = nil
                        table.insert(world.log, enemy.name .. " can gain Block again")
                    else
                        table.insert(world.log, enemy.name .. "'s No Block decreased to " .. enemy.status.no_block)
                    end
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
