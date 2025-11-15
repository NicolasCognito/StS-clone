-- Test Perseverance and Sands of Time cards
-- Tests retention-based block scaling and cost reduction

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local EndTurn = require("Pipelines.EndTurn")
local StartTurn = require("Pipelines.StartTurn")
local GetCost = require("Pipelines.GetCost")
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
            return false
        end

        if type(result) == "table" and result.needsContext then
            local request = world.combat.contextRequest
            local context = ContextProvider.execute(world, player,
                                                    request.contextProvider,
                                                    request.card)
            if request.stability == "stable" then
                world.combat.stableContext = context
            else
                -- Use indexed tempContext
                local contextId = request.contextId
                world.combat.tempContext[contextId] = context
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

print("=== Testing Perseverance ===")

-- TEST 1: Basic block (5)
print("\nTest 1: Perseverance basic block")
local world = World.createWorld({
    id = "Watcher",
    maxHp = 80,
    maxEnergy = 3,
    cards = {copyCard(Cards.Perseverance)},
    relics = {}
})

world.enemies = {copyEnemy(Enemies.Goblin)}
world.NoShuffle = true
StartCombat.execute(world)

local perseverance = findCardById(world.player.combatDeck, "Perseverance")
assert(perseverance, "Perseverance should be in deck")
assert(perseverance.block == 5, "Initial block should be 5")

playCardWithAutoContext(world, world.player, perseverance)
assert(world.player.block == 5, "Player should have 5 block: " .. world.player.block)
print("✓ Test 1 passed: Basic block works")

-- TEST 2: Retain once, verify block increases
print("\nTest 2: Perseverance retention increases block")
perseverance.state = "HAND"
EndTurn.execute(world, world.player)

assert(perseverance.state == "HAND", "Card should still be in hand")
assert(perseverance.block == 7, "Block should increase to 7 (5+2): " .. perseverance.block)
assert(perseverance.timesRetained == 1, "Times retained should be 1")
print("✓ Test 2 passed: Block increased on retention")

-- TEST 3: Multiple retentions
print("\nTest 3: Perseverance multiple retentions")
StartTurn.execute(world, world.player)
world.player.block = 0  -- Reset block

playCardWithAutoContext(world, world.player, perseverance)
assert(world.player.block == 7, "Player should have 7 block: " .. world.player.block)

perseverance.state = "HAND"
EndTurn.execute(world, world.player)
assert(perseverance.block == 9, "Block should increase to 9 (7+2): " .. perseverance.block)
print("✓ Test 3 passed: Multiple retentions stack")

-- TEST 4: Upgraded version (7 base, +3 per retain)
print("\nTest 4: Perseverance upgraded version")
local world2 = World.createWorld({
    id = "Watcher",
    maxHp = 80,
    maxEnergy = 3,
    cards = {},
    relics = {}
})

local upgradedPerseverance = copyCard(Cards.Perseverance)
upgradedPerseverance:onUpgrade()

world2.player.combatDeck = {upgradedPerseverance}
world2.enemies = {copyEnemy(Enemies.Goblin)}
world2.NoShuffle = true
StartCombat.execute(world2)

assert(upgradedPerseverance.block == 7, "Upgraded initial block should be 7")
assert(upgradedPerseverance.blockGainOnRetain == 3, "Upgraded gain should be 3")

playCardWithAutoContext(world2, world2.player, upgradedPerseverance)
assert(world2.player.block == 7, "Player should have 7 block")

upgradedPerseverance.state = "HAND"
EndTurn.execute(world2, world2.player)
assert(upgradedPerseverance.block == 10, "Upgraded block should increase to 10 (7+3): " .. upgradedPerseverance.block)
print("✓ Test 4 passed: Upgraded version works")

print("\n=== Testing Sands of Time ===")

-- TEST 5: Basic damage and cost
print("\nTest 5: Sands of Time basic damage and cost")
local world3 = World.createWorld({
    id = "Watcher",
    maxHp = 80,
    maxEnergy = 5,  -- Need enough energy for 4-cost card
    cards = {copyCard(Cards.SandsOfTime)},
    relics = {}
})

world3.enemies = {copyEnemy(Enemies.Goblin)}
world3.NoShuffle = true
StartCombat.execute(world3)

world3.enemies[1].hp = 50
world3.enemies[1].maxHp = 50

local sands = findCardById(world3.player.combatDeck, "SandsOfTime")
assert(sands, "Sands of Time should be in deck")
assert(sands.cost == 4, "Initial cost should be 4")
assert(sands.damage == 20, "Initial damage should be 20")

local actualCost = GetCost.execute(world3, world3.player, sands)
assert(actualCost == 4, "Actual cost should be 4: " .. actualCost)

playCardWithAutoContext(world3, world3.player, sands)
assert(world3.enemies[1].hp == 30, "Enemy should take 20 damage: " .. world3.enemies[1].hp)
print("✓ Test 5 passed: Basic damage and cost work")

-- TEST 6: Cost reduction after retention
print("\nTest 6: Sands of Time cost reduction on retention")
sands.state = "HAND"
EndTurn.execute(world3, world3.player)

assert(sands.state == "HAND", "Card should still be in hand")
assert(sands.timesRetained == 1, "Times retained should be 1")

-- Check cost reduction
local newCost = GetCost.execute(world3, world3.player, sands)
assert(newCost == 3, "Cost should reduce to 3 (4-1): " .. newCost)
print("✓ Test 6 passed: Cost reduced on retention")

-- TEST 7: Multiple retentions reduce cost to 0
print("\nTest 7: Sands of Time multiple retentions")
-- Retain 3 more times (total 4 retentions, cost should be 0)
for i = 1, 3 do
    StartTurn.execute(world3, world3.player)
    sands.state = "HAND"
    EndTurn.execute(world3, world3.player)
end

assert(sands.timesRetained == 4, "Times retained should be 4")
local finalCost = GetCost.execute(world3, world3.player, sands)
assert(finalCost == 0, "Cost should reduce to 0 (4-4): " .. finalCost)
print("✓ Test 7 passed: Multiple retentions reduce cost to 0")

-- TEST 8: Playing at reduced cost
print("\nTest 8: Sands of Time playing at reduced cost")
StartTurn.execute(world3, world3.player)
world3.player.energy = 1  -- Only 1 energy

local canPlay = GetCost.execute(world3, world3.player, sands)
assert(canPlay == 0, "Cost should be 0")

playCardWithAutoContext(world3, world3.player, sands)
assert(world3.player.energy == 1, "Playing free card should not cost energy: " .. world3.player.energy)
print("✓ Test 8 passed: Can play at reduced cost")

-- TEST 9: Upgraded version (26 damage)
print("\nTest 9: Sands of Time upgraded version")
local world4 = World.createWorld({
    id = "Watcher",
    maxHp = 80,
    maxEnergy = 5,
    cards = {},
    relics = {}
})

local upgradedSands = copyCard(Cards.SandsOfTime)
upgradedSands:onUpgrade()

world4.player.combatDeck = {upgradedSands}
world4.enemies = {copyEnemy(Enemies.Goblin)}
world4.NoShuffle = true
StartCombat.execute(world4)

world4.enemies[1].hp = 50
world4.enemies[1].maxHp = 50

assert(upgradedSands.damage == 26, "Upgraded damage should be 26")
assert(upgradedSands.cost == 4, "Cost should still be 4")

playCardWithAutoContext(world4, world4.player, upgradedSands)
assert(world4.enemies[1].hp == 24, "Enemy should take 26 damage: " .. world4.enemies[1].hp)
print("✓ Test 9 passed: Upgraded version works")

print("\n=== All Perseverance and Sands of Time tests passed! ===")
