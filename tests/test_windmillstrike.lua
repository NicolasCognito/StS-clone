-- Test Windmill Strike card
-- Tests retention-based damage scaling

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local EndTurn = require("Pipelines.EndTurn")
local StartTurn = require("Pipelines.StartTurn")
local ContextProvider = require("Pipelines.ContextProvider")

math.randomseed(1337)

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

local function playCardWithAutoContext(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            return true
        end
        if result == false then
            break
        end

        if type(result) == "table" and result.needsContext then
            local request = world.combat.contextRequest
            local context = ContextProvider.execute(world, player,
                                                    request.contextProvider,
                                                    request.card)
            if request.stability == "stable" then
                world.combat.stableContext = context
            else
                world.combat.tempContext = context
            end
            world.combat.contextRequest = nil
        end
    end
end

local function findCardById(deck, id)
    for _, card in ipairs(deck) do
        if card.id == id then
            return card
        end
    end
    return nil
end

print("=== Testing Windmill Strike ===")

-- TEST 1: Basic damage (7)
print("\nTest 1: Basic damage")
local world = World.createWorld({
    id = "Watcher",
    maxHp = 80,
    maxEnergy = 3,
    cards = {copyCard(Cards.WindmillStrike)},
    relics = {}
})

world.enemies = {copyEnemy(Enemies.Goblin)}
world.NoShuffle = true
StartCombat.execute(world)

-- Set enemy HP high enough to survive
world.enemies[1].hp = 50
world.enemies[1].maxHp = 50

local windmill = findCardById(world.player.combatDeck, "WindmillStrike")
assert(windmill, "Windmill Strike should be in deck")
assert(windmill.damage == 7, "Initial damage should be 7")

playCardWithAutoContext(world, world.player, windmill)
assert(world.enemies[1].hp == 43, "Enemy should take 7 damage: " .. world.enemies[1].hp)
print("✓ Test 1 passed: Basic damage works")

-- TEST 2: Retain once, verify damage increases
print("\nTest 2: Retention increases damage")
-- Add Windmill Strike to hand
windmill.state = "HAND"

EndTurn.execute(world, world.player)

-- Check that card was retained and damage increased
assert(windmill.state == "HAND", "Card should still be in hand after end turn")
assert(windmill.damage == 11, "Damage should increase to 11 (7+4): " .. windmill.damage)
assert(windmill.timesRetained == 1, "Times retained should be 1")
print("✓ Test 2 passed: Damage increased on retention")

-- TEST 3: Multiple retentions
print("\nTest 3: Multiple retentions")
StartTurn.execute(world, world.player)

-- Play the card again (should have 11 damage now)
local enemyHpBefore = world.enemies[1].hp
playCardWithAutoContext(world, world.player, windmill)
assert(world.enemies[1].hp == enemyHpBefore - 11, "Enemy should take 11 damage")

-- Put it back in hand and retain again
windmill.state = "HAND"
EndTurn.execute(world, world.player)
assert(windmill.damage == 15, "Damage should increase to 15 (11+4): " .. windmill.damage)
assert(windmill.timesRetained == 2, "Times retained should be 2")
print("✓ Test 3 passed: Multiple retentions stack")

-- TEST 4: Upgraded version (10 base, +5 per retain)
print("\nTest 4: Upgraded version")
local world2 = World.createWorld({
    id = "Watcher",
    maxHp = 80,
    maxEnergy = 3,
    cards = {},
    relics = {}
})

local upgradedWindmill = copyCard(Cards.WindmillStrike)
upgradedWindmill:onUpgrade()

world2.player.combatDeck = {upgradedWindmill}
world2.enemies = {copyEnemy(Enemies.Goblin)}
world2.NoShuffle = true
StartCombat.execute(world2)

world2.enemies[1].hp = 50
world2.enemies[1].maxHp = 50

assert(upgradedWindmill.damage == 10, "Upgraded initial damage should be 10")
assert(upgradedWindmill.damageGainOnRetain == 5, "Upgraded gain should be 5")

playCardWithAutoContext(world2, world2.player, upgradedWindmill)
assert(world2.enemies[1].hp == 40, "Enemy should take 10 damage")

-- Retain and check damage increase
upgradedWindmill.state = "HAND"
EndTurn.execute(world2, world2.player)
assert(upgradedWindmill.damage == 15, "Upgraded damage should increase to 15 (10+5): " .. upgradedWindmill.damage)
print("✓ Test 4 passed: Upgraded version works")

-- TEST 5: Damage resets between combats (combat deck is deep copy)
print("\nTest 5: Damage persists within combat only")
-- This is inherently true because combatDeck is a deep copy from masterDeck
-- and gets discarded at end of combat. We verify the masterDeck is unchanged.
local masterWindmill = findCardById(world.player.masterDeck, "WindmillStrike")
assert(masterWindmill.damage == 7, "Master deck card should still have 7 damage")
print("✓ Test 5 passed: Damage is combat-only (master deck unchanged)")

print("\n=== All Windmill Strike tests passed! ===")
