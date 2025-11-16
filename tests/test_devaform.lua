local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local StartTurn = require("Pipelines.StartTurn")
local EndTurn = require("Pipelines.EndTurn")
local PlayCard = require("Pipelines.PlayCard")

local function createWatcherWorld(deckCount)
    local cards = {}
    for i = 1, deckCount do
        table.insert(cards, Utils.copyCardTemplate(Cards.Strike))
    end

    local world = World.createWorld({
        id = "Watcher",
        maxHp = 70,
        maxEnergy = 3,
        cards = cards
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    return world
end

print("=== Test 1: Deva Form applies Deva statuses ===")
do
    local world = createWatcherWorld(12)
    local card = Utils.copyCardTemplate(Cards.DevaForm)
    card.state = "HAND"
    table.insert(world.player.combatDeck, card)
    world.player.energy = 5

    local result = PlayCard.execute(world, world.player, card)
    assert(result == true, "Deva Form should be playable")
    assert(world.player.status.deva == 1, "Deva stacks should start at 1")
    assert(world.player.status.deva_growth == 1, "Deva growth should be 1 stack")

    print("✓ Deva Form grants initial energy gain and growth stacks")
end

print("\n=== Test 2: Deva Form energy gain scales every turn ===")
do
    local world = createWatcherWorld(12)
    EndTurn.execute(world, world.player)

    world.player.status.deva = 2
    world.player.status.deva_growth = 1
    world.log = {}

    StartTurn.execute(world, world.player)
    local baseEnergy = world.player.maxEnergy
    assert(world.player.energy == baseEnergy + 2, "Should gain 2 extra energy (got " .. world.player.energy .. ")")
    assert(world.player.status.deva == 3, "Energy gain should increase to 3 (got " .. world.player.status.deva .. ")")

    world.log = {}
    EndTurn.execute(world, world.player)
    StartTurn.execute(world, world.player)
    assert(world.player.energy == baseEnergy + 3, "Should gain 3 extra energy after growth (got " .. world.player.energy .. ")")
    assert(world.player.status.deva == 4, "Energy gain should increase to 4 (got " .. world.player.status.deva .. ")")

    print("✓ Deva Form adds energy and ramps up each turn")
end

