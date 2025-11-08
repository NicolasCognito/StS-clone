-- ENEMY TAKE TURN PIPELINE
-- world: the complete game state
-- enemy: the enemy taking its turn
-- player: the player being attacked
--
-- Handles:
-- - Execute enemy's intent action (push events)
-- - Process effect queue
-- - Combat logging

local EnemyTakeTurn = {}

local ProcessEffectQueue = require("Pipelines.ProcessEffectQueue")

function EnemyTakeTurn.execute(world, enemy, player)
    table.insert(world.log, "--- " .. enemy.name .. "'s Turn ---")

    -- Reset enemy block at start of turn
    enemy.block = 0

    -- Execute enemy's intent action (pushes events to queue)
    if enemy.executeIntent then
        enemy:executeIntent(world, player)
    end

    -- Process all queued events
    ProcessEffectQueue.execute(world)

    -- Tick down enemy status effects
    if enemy.status then
        if enemy.status.vulnerable and enemy.status.vulnerable > 0 then
            enemy.status.vulnerable = enemy.status.vulnerable - 1
        end
        if enemy.status.weak and enemy.status.weak > 0 then
            enemy.status.weak = enemy.status.weak - 1
        end
    end

    table.insert(world.log, enemy.name .. " ended turn")
end

return EnemyTakeTurn
