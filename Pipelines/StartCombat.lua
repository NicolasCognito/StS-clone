-- START COMBAT PIPELINE
-- Initializes combat-specific context before the player takes the first turn

local StartCombat = {}

local EventQueue = require("Pipelines.EventQueue")
local StartTurn = require("Pipelines.StartTurn")
local Utils = require("utils")

function StartCombat.execute(world)
    world.combat = {
        timesHpLost = 0,
        cardsDiscardedThisTurn = 0,
        powersPlayedThisCombat = 0,
        -- Context system
        stableContext = nil,      -- Persists across duplications (e.g., enemy target)
        tempContext = nil,        -- Re-collected on duplications (e.g., card discard)
        latestContext = nil,      -- Points to the most recently collected context
        contextRequest = nil      -- Request for context collection: {card, contextProvider, stability}
    }

    world.queue = EventQueue.new()
    world.log = {}

    -- Ensure combat-only status/power tables exist
    world.player.status = world.player.status or {}
    world.player.powers = world.player.powers or {}

    -- Create combatDeck as a deep copy of masterDeck
    -- This ensures combat-only modifications (generated cards, temporary upgrades)
    -- don't affect the player's permanent deck
    world.player.combatDeck = Utils.deepCopyDeck(world.player.masterDeck)

    -- Initialize all combat cards to DECK state and clear combat-only properties
    for _, card in ipairs(world.player.combatDeck) do
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

