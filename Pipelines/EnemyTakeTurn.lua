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
local StatusEffects = require("Data.statuseffects")

-- Helper: Call onStartTurn hooks for all status effects on a combatant
local function triggerStartTurnHooks(world, combatant)
    if not combatant.status then return end

    for statusKey, statusDef in pairs(StatusEffects) do
        if statusDef.onStartTurn and combatant.status[statusKey] and combatant.status[statusKey] > 0 then
            statusDef.onStartTurn(world, combatant)
        end
    end
end

-- Helper: Call onEndTurn hooks for all status effects on a combatant
local function triggerEndTurnHooks(world, combatant)
    if not combatant.status then return end

    for statusKey, statusDef in pairs(StatusEffects) do
        if statusDef.onEndTurn and combatant.status[statusKey] and combatant.status[statusKey] > 0 then
            statusDef.onEndTurn(world, combatant)
        end
    end
end

function EnemyTakeTurn.execute(world, enemy, player)
    table.insert(world.log, "--- " .. enemy.name .. "'s Turn ---")

    enemy.status = enemy.status or {}

    -- Trigger onStartTurn hooks for this enemy's status effects
    -- (Poison, Bias, Wraith Form, Regrow, etc.)
    triggerStartTurnHooks(world, enemy)

    -- Process any events queued by status effect hooks
    ProcessEventQueue.execute(world)

    -- If enemy is reviving, skip the rest of the turn (no intent execution)
    if enemy.reviving then
        table.insert(world.log, enemy.name .. " is reviving (no action)")

        -- Still process end turn hooks for status effects
        triggerEndTurnHooks(world, enemy)
        ProcessEventQueue.execute(world)

        table.insert(world.log, enemy.name .. " ended turn")
        return
    end

    -- Reset enemy block at start of turn (unless Blur is active)
    if enemy.status.blur and enemy.status.blur > 0 then
        table.insert(world.log, enemy.name .. "'s Block retained (Blur)")
    else
        enemy.block = 0
    end

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

    -- Trigger onEndTurn hooks for this enemy's status effects
    -- (Ritual, Regeneration, Metallicize, Plated Armor, etc.)
    triggerEndTurnHooks(world, enemy)

    -- Process any events queued by status effect hooks
    ProcessEventQueue.execute(world)

    -- NOTE: Status effects (vulnerable, weak, frail, etc.) are now ticked down
    -- in the EndRound pipeline, not here. This is because they are "End of Round"
    -- effects, not "End of Turn" effects.

    table.insert(world.log, enemy.name .. " ended turn")
end

return EnemyTakeTurn
