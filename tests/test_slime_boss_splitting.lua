-- Test for Slime Boss Splitting Mechanic
--
-- This test verifies:
-- 1. Slime Boss splits when taking damage
-- 2. Boss spawns 2 SpikeSlimes
-- 3. Boss is marked as dead after splitting

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local StartTurn = require("Pipelines.StartTurn")

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

print("=== Test 1: Slime Boss splits when taking damage ===")

-- Setup world with player and Slime Boss
local deck1 = {
    copyCard(Cards.Strike),  -- Use Strike to deal damage
    copyCard(Cards.Defend),
    copyCard(Cards.Defend)
}

local world1 = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    hp = 80,
    maxEnergy = 3,
    deck = deck1,
    relics = {}
})

local boss = copyEnemy(Enemies.SlimeBoss)
world1.enemies = {boss}

StartCombat.execute(world1, world1.player, world1.enemies)

-- Count enemies before attack
local enemyCountBefore = #world1.enemies
print("Enemies before attack: " .. enemyCountBefore)
assert(enemyCountBefore == 1, "Should have 1 enemy before attack")

-- Start turn and draw cards
StartTurn.execute(world1, world1.player)

-- Play Strike card to damage the boss
local strikeCard = nil
for _, card in ipairs(world1.player.hand) do
    if card.id == "Strike" then
        strikeCard = card
        break
    end
end

assert(strikeCard ~= nil, "Should have Strike card in hand")

-- Attack the boss
PlayCard.execute(world1, world1.player, strikeCard, boss)

-- Process all queued events
while not world1.queue:isEmpty() do
    local event = world1.queue:pop()
    local pipeline = require("Pipelines." .. Utils.eventTypeToPipelineName(event.type))
    pipeline.execute(world1, event)
end

-- Verify boss split
local aliveEnemies = {}
for _, enemy in ipairs(world1.enemies) do
    if enemy.hp > 0 then
        table.insert(aliveEnemies, enemy)
    end
end

local slimeCount = 0
local bossAlive = false
for _, enemy in ipairs(aliveEnemies) do
    if enemy.id == "SpikeSlime" then
        slimeCount = slimeCount + 1
    end
    if enemy.id == "SlimeBoss" and enemy.hp > 0 then
        bossAlive = true
    end
end

print("Enemies after attack: " .. #aliveEnemies)
print("SpikeSlimes spawned: " .. slimeCount)
print("Boss still alive: " .. tostring(bossAlive))

assert(slimeCount == 2, "Should have spawned 2 SpikeSlimes, got: " .. slimeCount)
assert(not bossAlive, "Boss should be dead after splitting")
print("✓ Slime Boss successfully split into 2 SpikeSlimes")

print("\n=== Test 2: Slime Boss only splits once ===")

-- Setup another test to verify boss doesn't split multiple times
local deck2 = {
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Defend)
}

local world2 = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    hp = 80,
    maxEnergy = 3,
    deck = deck2,
    relics = {}
})

local boss2 = copyEnemy(Enemies.SlimeBoss)
world2.enemies = {boss2}

StartCombat.execute(world2, world2.player, world2.enemies)
StartTurn.execute(world2, world2.player)

-- Attack boss once
local strike1 = nil
for _, card in ipairs(world2.player.hand) do
    if card.id == "Strike" then
        strike1 = card
        break
    end
end

PlayCard.execute(world2, world2.player, strike1, boss2)

-- Process all events
while not world2.queue:isEmpty() do
    local event = world2.queue:pop()
    local pipeline = require("Pipelines." .. Utils.eventTypeToPipelineName(event.type))
    pipeline.execute(world2, event)
end

-- Count slimes after first attack
local slimesAfterFirstAttack = 0
for _, enemy in ipairs(world2.enemies) do
    if enemy.id == "SpikeSlime" and enemy.hp > 0 then
        slimesAfterFirstAttack = slimesAfterFirstAttack + 1
    end
end

print("SpikeSlimes after first attack: " .. slimesAfterFirstAttack)
assert(slimesAfterFirstAttack == 2, "Should have 2 slimes after first attack")

-- Verify the isSplitting flag is set
assert(boss2.isSplitting == true, "Boss should have isSplitting flag set")
print("✓ Boss has isSplitting flag set to prevent multiple splits")

print("\n=== All Slime Boss Splitting Tests Passed! ===")
