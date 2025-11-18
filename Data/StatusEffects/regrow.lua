-- REGROW STATUS EFFECT
-- Used by Darklings for their revival mechanic (Life Link)
-- When a Darkling dies, it enters a "regrow" state for 2 turns
-- On the second turn, if other Darklings are alive, it revives with half HP

return {
    regrow = {
        id = "regrow",
        name = "Regrow",
        description = "Reviving. Will return with half HP if allies are alive.",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = false,

        onStartTurn = function(world, enemy)
            local Utils = require("utils")
            local enemyName = enemy.name or enemy.id or "Enemy"

            -- Decrement the regrow counter
            Utils.Decrement(enemy, "regrow", 1)
            local remaining = enemy.status.regrow or 0

            if remaining > 0 then
                -- Still regrowing
                Utils.log(world, enemyName .. " will revive in " .. remaining .. " turn(s)")
            else
                -- Revival time! Check if there are living allies
                local alliesAlive = false

                if world.enemies then
                    for _, other in ipairs(world.enemies) do
                        -- Check if another Darkling is alive (not this one, not reviving, has HP > 0)
                        if other ~= enemy
                           and other.reviveType == "darkling"
                           and other.hp > 0
                           and not other.reviving then
                            alliesAlive = true
                            break
                        end
                    end
                end

                if alliesAlive then
                    -- REVIVE with half HP (rounded down)
                    enemy.hp = math.floor(enemy.maxHp / 2)
                    enemy.reviving = false
                    enemy.status.regrow = nil

                    Utils.log(world, enemyName .. " has revived with " .. enemy.hp .. " HP!")

                    -- Select a new intent for the revived enemy
                    if enemy.selectIntent then
                        enemy:selectIntent(world, world.player)
                    end
                else
                    -- No allies alive - die permanently
                    enemy.dead = true
                    enemy.reviving = false
                    enemy.status.regrow = nil

                    Utils.log(world, enemyName .. " crumbles to dust (no allies to revive)")
                end
            end
        end
    }
}
