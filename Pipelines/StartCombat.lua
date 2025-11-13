-- START COMBAT PIPELINE
-- Initializes combat-specific context before the player takes the first turn

local StartCombat = {}

local World = require("World")
local EventQueue = require("Pipelines.EventQueue")
local CardQueue = require("Pipelines.CardQueue")
local StartTurn = require("Pipelines.StartTurn")
local Utils = require("utils")

function StartCombat.execute(world)
    world.combat = World.initCombatState()

    -- Initialize lastPlayedCard tracking (persists across turns within combat)
    world.lastPlayedCard = nil

    world.queue = EventQueue.new()
    world.cardQueue = CardQueue.new()
    world.log = {}

    -- Ensure combat-only status table exists
    world.player.status = world.player.status or {}
    local permanentStrength = world.player.permanentStrength or 0
    if permanentStrength ~= 0 then
        world.player.status.strength = (world.player.status.strength or 0) + permanentStrength
        table.insert(world.log, string.format("%s benefits from %d permanent Strength.", world.player.name, permanentStrength))
    end

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

    -- Shuffle the combat deck for random card order
    Utils.shuffleDeck(world.player.combatDeck, world)

    world.player.block = 0
    world.player.energy = world.player.maxEnergy
    world.player.hp = world.player.currentHp
    local pendingRestEnergy = world.pendingRestSiteEnergy or 0
    if pendingRestEnergy > 0 then
        world.player.energy = world.player.energy + pendingRestEnergy
        table.insert(world.log, string.format("Ancient Tea Set grants +%d energy this turn.", pendingRestEnergy))
        world.pendingRestSiteEnergy = 0
    end

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

