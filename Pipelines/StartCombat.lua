-- START COMBAT PIPELINE
-- world: the complete game state
--
-- Handles:
-- - Initialize combat context (queue, combat counters, log)
-- - Initialize card states to DECK
-- - Reset player combat state (block, energy, hp)
-- - Apply relic combat-start effects
-- - Draw initial hand (calls StartTurn)

local StartCombat = {}

local EventQueue = require("Pipelines.EventQueue")
local StartTurn = require("Pipelines.StartTurn")

function StartCombat.execute(world)
    -- Add combat-specific temporary context to world
    world.combat = {
        timesHpLost = 0,              -- For Blood for Blood cost reduction (and Masterful Stab increase)
        cardsDiscardedThisTurn = 0,   -- For Eviscerate cost reduction
        powersPlayedThisCombat = 0,   -- For Force Field cost reduction
    }

    world.queue = EventQueue.new()
    world.log = {}

    -- Initialize card states to DECK
    for _, card in ipairs(world.player.cards) do
        card.state = "DECK"
    end

    -- Reset combat-specific player state
    world.player.block = 0
    world.player.energy = 3
    world.player.hp = world.player.currentHp

    -- Apply relic combat-start effects
    for _, relic in ipairs(world.player.relics) do
        if relic.onCombatStart then
            relic:onCombatStart(world)
        end

        -- Special case for Snecko Eye (apply Confused status)
        if relic.id == "Snecko_Eye" then
            -- Initialize status table if needed
            if not world.player.status then
                world.player.status = {}
            end
            -- Apply permanent Confused for the combat
            world.player.status.confused = 999  -- Lasts entire combat
            table.insert(world.log, world.player.name .. " is Confused!")
        end
    end

    -- Draw initial hand (calls StartTurn which draws cards)
    StartTurn.execute(world, world.player)
end

return StartCombat
