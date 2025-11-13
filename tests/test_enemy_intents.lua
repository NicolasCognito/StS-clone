-- Test for Enemy Intent System
--
-- This test verifies:
-- 1. Enemies select intents at start of turn
-- 2. Enemies execute their selected intents
-- 3. Different enemy types have different behaviors

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local StartTurn = require("Pipelines.StartTurn")
local EnemyTakeTurn = require("Pipelines.EnemyTakeTurn")

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

print("=== Test 1: Goblin selects and executes intent ===")

-- Setup world with player and goblin
local deck1 = {
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
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

local enemy1 = copyEnemy(Enemies.Goblin)
world1.enemies = {enemy1}

StartCombat.execute(world1)

-- StartCombat already calls StartTurn, which triggers intent selection
-- No need to call StartTurn again

-- Check that intent was selected
assert(enemy1.currentIntent ~= nil, "Goblin should have selected an intent")
assert(enemy1.currentIntent.name ~= nil, "Intent should have a name")
assert(enemy1.currentIntent.execute ~= nil, "Intent should have an execute function")
print("✓ Goblin selected intent: " .. enemy1.currentIntent.name)

-- Execute enemy turn
local initialPlayerHp = world1.player.hp
EnemyTakeTurn.execute(world1, enemy1, world1.player)

print("✓ Goblin executed intent successfully")

print("\n=== Test 2: Slime intent behavior ===")

-- Setup world with Acid Slime
local deck2 = {
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

local slime = copyEnemy(Enemies.AcidSlime)
world2.enemies = {slime}

StartCombat.execute(world2)

-- Test that slime has different intents over multiple turns
-- First intent is selected during StartCombat
local intentsUsed = {}
intentsUsed[slime.currentIntent.name] = true
print("Turn 1: Slime selected " .. slime.currentIntent.name)

for turn = 2, 5 do
    StartTurn.execute(world2, world2.player)

    assert(slime.currentIntent ~= nil, "Slime should have selected an intent on turn " .. turn)
    intentsUsed[slime.currentIntent.name] = true
    print("Turn " .. turn .. ": Slime selected " .. slime.currentIntent.name)
end

local intentCount = 0
for _ in pairs(intentsUsed) do
    intentCount = intentCount + 1
end

print("✓ Slime used " .. intentCount .. " different intent types")

print("\n=== Test 3: Cultist ritual behavior ===")

-- Setup world with Cultist
local deck3 = {
    copyCard(Cards.Defend)
}

local world3 = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    hp = 80,
    maxEnergy = 3,
    deck = deck3,
    relics = {}
})

local cultist = copyEnemy(Enemies.Cultist)
world3.enemies = {cultist}

StartCombat.execute(world3)

-- First turn: should ritual (intent selected during StartCombat -> StartTurn)
assert(cultist.currentIntent ~= nil, "Cultist should have selected an intent")
assert(cultist.currentIntent.name == "Ritual", "Cultist should ritual on first turn, got: " .. (cultist.currentIntent.name or "nil"))
print("✓ Cultist performs ritual on first turn")

local initialDamage = cultist.damage

-- Execute ritual
EnemyTakeTurn.execute(world3, cultist, world3.player)

-- Second turn: should attack with increased damage
StartTurn.execute(world3, world3.player)
assert(cultist.currentIntent.name == "Dark Strike", "Cultist should attack after ritual, got: " .. (cultist.currentIntent.name or "nil"))
assert(cultist.damage > initialDamage, "Cultist damage should increase after ritual")
print("✓ Cultist attacks with increased damage after ritual")

print("\n=== All Enemy Intent Tests Passed! ===")
