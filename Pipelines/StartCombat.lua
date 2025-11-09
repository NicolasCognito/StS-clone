-- START COMBAT PIPELINE
-- Initializes combat-specific context before the player takes the first turn

local StartCombat = {}

local EventQueue = require("Pipelines.EventQueue")
local StartTurn = require("Pipelines.StartTurn")

function StartCombat.execute(world)
    world.combat = {
        timesHpLost = 0,
        cardsDiscardedThisTurn = 0,
        powersPlayedThisCombat = 0
    }

    world.queue = EventQueue.new()
    world.log = {}

    for _, card in ipairs(world.player.cards or {}) do
        card.state = "DECK"
        card.confused = nil
        card.costsZeroThisTurn = nil
        card.timesRetained = nil
        card.retainCostReduction = nil
    end

    world.player.block = 0
    world.player.energy = world.player.maxEnergy
    world.player.hp = world.player.currentHp

    for _, relic in ipairs(world.player.relics or {}) do
        if relic.onCombatStart then
            relic:onCombatStart(world)
        end

        if relic.id == "Snecko_Eye" then
            world.player.status = world.player.status or {}
            world.player.status.confused = 999
            table.insert(world.log, world.player.name .. " is Confused!")
        end
    end

    StartTurn.execute(world, world.player)
end

return StartCombat

