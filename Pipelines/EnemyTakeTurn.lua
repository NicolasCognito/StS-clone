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

local ProcessEventQueue = require("Pipelines.ProcessEventQueue")

function EnemyTakeTurn.execute(world, enemy, player)
    table.insert(world.log, "--- " .. enemy.name .. "'s Turn ---")

    enemy.status = enemy.status or {}
    if enemy.status.bias and enemy.status.bias > 0 then
        local biasLoss = enemy.status.bias
        enemy.status.focus = (enemy.status.focus or 0) - biasLoss
        table.insert(world.log, enemy.name .. " lost " .. biasLoss .. " Focus from Bias")
    end

    if enemy.status.wraith_form and enemy.status.wraith_form > 0 then
        local dexLoss = enemy.status.wraith_form
        enemy.status.dexterity = (enemy.status.dexterity or 0) - dexLoss
        table.insert(world.log, enemy.name .. " lost " .. dexLoss .. " Dexterity from Wraith Form")
    end

    -- Reset enemy block at start of turn
    enemy.block = 0

    -- Log the enemy's intent
    if enemy.currentIntent then
        local intentName = enemy.currentIntent.name or "Unknown"
        local intentDesc = enemy.currentIntent.description or ""
        table.insert(world.log, enemy.name .. " executes: " .. intentName .. (intentDesc ~= "" and (" (" .. intentDesc .. ")") or ""))

        -- Record intent in history (for AI decision-making)
        enemy.intentHistory = enemy.intentHistory or {}
        table.insert(enemy.intentHistory, intentName)
    end

    -- Execute enemy's intent action (pushes events to queue)
    if enemy.executeIntent then
        enemy:executeIntent(world, player)
    end

    -- Process all queued events
    ProcessEventQueue.execute(world)

    -- NOTE: Status effects (vulnerable, weak, frail, etc.) are now ticked down
    -- in the EndRound pipeline, not here. This is because they are "End of Round"
    -- effects, not "End of Turn" effects.

    table.insert(world.log, enemy.name .. " ended turn")
end

return EnemyTakeTurn
