-- Test for Stance System Integration with Combat
--
-- This test verifies:
-- 1. Wrath stance doubles damage dealt by player
-- 2. Wrath stance doubles damage taken by player
-- 3. Divinity stance triples damage dealt by player
-- 4. Divinity auto-exits at start of next turn
-- 5. Stance damage modifiers work with other damage calculations

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local DealDamage = require("Pipelines.DealDamage")
local ChangeStance = require("Pipelines.ChangeStance")
local StartTurn = require("Pipelines.StartTurn")

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

print("=== Test 1: Wrath doubles damage dealt ===")

local world1 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {copyCard(Cards.Strike)},
    relics = {}
})

local enemy1 = copyEnemy(Enemies.Cultist)
enemy1.hp = 100  -- Set high HP so we can see exact damage
world1.enemies = {enemy1}

StartCombat.execute(world1, world1.player, world1.enemies)

-- Deal damage without Wrath
local strikeCard = world1.player.combatDeck[1]
DealDamage.execute(world1, {
    attacker = world1.player,
    defender = enemy1,
    card = strikeCard
})

local damageWithoutWrath = 100 - enemy1.hp
print("Damage without Wrath: " .. damageWithoutWrath)

-- Reset enemy HP
enemy1.hp = 100

-- Enter Wrath and deal damage again
ChangeStance.execute(world1, {newStance = "Wrath"})
DealDamage.execute(world1, {
    attacker = world1.player,
    defender = enemy1,
    card = strikeCard
})

local damageWithWrath = 100 - enemy1.hp
print("Damage with Wrath: " .. damageWithWrath)

assert(damageWithWrath == damageWithoutWrath * 2, "Wrath should double damage dealt, expected " .. (damageWithoutWrath * 2) .. " got " .. damageWithWrath)
print("✓ Wrath doubles damage dealt")

print("\n=== Test 2: Wrath doubles damage taken ===")

local world2 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {},
    relics = {}
})

local enemy2 = copyEnemy(Enemies.Goblin)
world2.enemies = {enemy2}

StartCombat.execute(world2, world2.player, world2.enemies)

-- Create a simple damage card for enemy to use
local enemyAttack = {damage = 10}

-- Take damage without Wrath
world2.player.hp = 100
world2.player.block = 0
DealDamage.execute(world2, {
    attacker = enemy2,
    defender = world2.player,
    card = enemyAttack
})

local damageWithoutWrath2 = 100 - world2.player.hp
print("Damage taken without Wrath: " .. damageWithoutWrath2)

-- Reset player HP and enter Wrath
world2.player.hp = 100
world2.player.block = 0
ChangeStance.execute(world2, {newStance = "Wrath"})
DealDamage.execute(world2, {
    attacker = enemy2,
    defender = world2.player,
    card = enemyAttack
})

local damageWithWrath2 = 100 - world2.player.hp
print("Damage taken with Wrath: " .. damageWithWrath2)

assert(damageWithWrath2 == damageWithoutWrath2 * 2, "Wrath should double damage taken, expected " .. (damageWithoutWrath2 * 2) .. " got " .. damageWithWrath2)
print("✓ Wrath doubles damage taken")

print("\n=== Test 3: Divinity triples damage dealt ===")

local world3 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {copyCard(Cards.Strike)},
    relics = {}
})

local enemy3 = copyEnemy(Enemies.Cultist)
enemy3.hp = 100
world3.enemies = {enemy3}

StartCombat.execute(world3, world3.player, world3.enemies)

-- Deal damage without Divinity
local strikeCard3 = world3.player.combatDeck[1]
DealDamage.execute(world3, {
    attacker = world3.player,
    defender = enemy3,
    card = strikeCard3
})

local damageWithoutDivinity = 100 - enemy3.hp
print("Damage without Divinity: " .. damageWithoutDivinity)

-- Reset enemy HP
enemy3.hp = 100

-- Enter Divinity and deal damage again
ChangeStance.execute(world3, {newStance = "Divinity"})
DealDamage.execute(world3, {
    attacker = world3.player,
    defender = enemy3,
    card = strikeCard3
})

local damageWithDivinity = 100 - enemy3.hp
print("Damage with Divinity: " .. damageWithDivinity)

assert(damageWithDivinity == damageWithoutDivinity * 3, "Divinity should triple damage dealt, expected " .. (damageWithoutDivinity * 3) .. " got " .. damageWithDivinity)
print("✓ Divinity triples damage dealt")

print("\n=== Test 4: Divinity auto-exits at start of turn ===")

local world4 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {copyCard(Cards.Defend), copyCard(Cards.Defend), copyCard(Cards.Defend), copyCard(Cards.Defend), copyCard(Cards.Defend)},
    relics = {}
})

local enemy4 = copyEnemy(Enemies.Goblin)
world4.enemies = {enemy4}

StartCombat.execute(world4, world4.player, world4.enemies)

-- Enter Divinity
ChangeStance.execute(world4, {newStance = "Divinity"})
assert(world4.player.currentStance == "Divinity", "Player should be in Divinity")

-- Start next turn - Divinity should auto-exit
StartTurn.execute(world4, world4.player)

assert(world4.player.currentStance == nil, "Divinity should auto-exit at start of turn, got: " .. tostring(world4.player.currentStance))
print("✓ Divinity automatically exits at start of turn")

print("\n=== Test 5: Both attacker and defender Wrath stacks (x4 damage) ===")

local world5 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 100,
    maxEnergy = 3,
    deck = {copyCard(Cards.Strike)},
    relics = {}
})

local enemy5 = copyEnemy(Enemies.Cultist)
enemy5.hp = 100
world5.enemies = {enemy5}

StartCombat.execute(world5, world5.player, world5.enemies)

-- Get base damage first
local strikeCard5 = world5.player.combatDeck[1]
DealDamage.execute(world5, {
    attacker = world5.player,
    defender = enemy5,
    card = strikeCard5
})
local baseDamage = 100 - enemy5.hp

-- Reset and put both in Wrath
enemy5.hp = 100
world5.player.currentStance = "Wrath"
enemy5.currentStance = "Wrath"

DealDamage.execute(world5, {
    attacker = world5.player,
    defender = enemy5,
    card = strikeCard5
})

local doubleWrathDamage = 100 - enemy5.hp
print("Base damage: " .. baseDamage)
print("Both in Wrath damage: " .. doubleWrathDamage)

-- Should be x2 for attacker Wrath, then x2 again for defender Wrath = x4 total
assert(doubleWrathDamage == baseDamage * 4, "Both in Wrath should quadruple damage, expected " .. (baseDamage * 4) .. " got " .. doubleWrathDamage)
print("✓ Both attacker and defender in Wrath stacks multiplicatively (x4)")

print("\n=== Test 6: Calm doesn't affect damage ===")

local world6 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {copyCard(Cards.Strike)},
    relics = {}
})

local enemy6 = copyEnemy(Enemies.Cultist)
enemy6.hp = 100
world6.enemies = {enemy6}

StartCombat.execute(world6, world6.player, world6.enemies)

-- Deal damage without stance
local strikeCard6 = world6.player.combatDeck[1]
DealDamage.execute(world6, {
    attacker = world6.player,
    defender = enemy6,
    card = strikeCard6
})
local damageNoStance = 100 - enemy6.hp

-- Reset and enter Calm
enemy6.hp = 100
ChangeStance.execute(world6, {newStance = "Calm"})
DealDamage.execute(world6, {
    attacker = world6.player,
    defender = enemy6,
    card = strikeCard6
})
local damageInCalm = 100 - enemy6.hp

assert(damageInCalm == damageNoStance, "Calm should not affect damage, expected " .. damageNoStance .. " got " .. damageInCalm)
print("✓ Calm stance does not modify damage")

print("\n=== All Stance Combat Integration Tests Passed! ===")
