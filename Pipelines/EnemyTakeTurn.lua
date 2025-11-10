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

    -- NOTE: Status effects (vulnerable, weak, frail, etc.) are now ticked down
    -- in the EndRound pipeline, not here. This is because they are "End of Round"
    -- effects, not "End of Turn" effects.

    table.insert(world.log, enemy.name .. " ended turn")
end

return EnemyTakeTurn
