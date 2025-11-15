-- TEST: Panache Power
-- Tests Panache power that triggers every 5 cards played

local World = require("World")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")
local Utils = require("utils")

print("=== Testing Panache Power ===\n")

-- Helper: play a card to completion, auto-fulfilling context requests
local function playCard(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            return true
        end

        if type(result) == "table" and result.needsContext then
            local request = world.combat.contextRequest
            local context = ContextProvider.execute(world, player, request.contextProvider, request.card)

            if request.stability == "stable" then
                world.combat.stableContext = context
            else
                world.combat.tempContext = context
            end
            world.combat.contextRequest = nil
        end
    end
end

-- Test 1: Panache triggers on 5th card
print("Test 1: Panache triggers on 5th card")
local world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER",
    maxEnergy = 10
})

-- Create 5 Strikes and 1 Panache
local panache = Utils.deepCopyCard(Cards.Panache)
panache.state = "HAND"

local strikes = {}
for i = 1, 5 do
    local strike = Utils.deepCopyCard(Cards.Strike)
    strike.state = "HAND"
    table.insert(strikes, strike)
end

world.player.masterDeck = {panache}
for _, strike in ipairs(strikes) do
    table.insert(world.player.masterDeck, strike)
end
world.player.combatDeck = Utils.deepCopyTable(world.player.masterDeck)

world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
world.enemies[1].hp = 100
world.enemies[1].maxHp = 100

StartCombat.execute(world)

-- Play Panache first
playCard(world, world.player, panache)
assert(Utils.hasPower(world.player, "Panache"), "Player should have Panache power")
assert(world.player.status.panache == 10, "Panache damage should be 10")
print("Panache power applied: " .. world.player.status.panache .. " damage")

-- Play 4 Strikes (no trigger yet)
local enemyHpBefore = world.enemies[1].hp
for i = 1, 4 do
    playCard(world, world.player, strikes[i])
end
print("After 4 strikes, enemy HP: " .. world.enemies[1].hp)
assert(#world.combat.cardsPlayedThisTurn == 5, "Should have 5 cards played (Panache + 4 Strikes)")

-- Play 5th Strike - should trigger Panache
playCard(world, world.player, strikes[5])
print("After 5th strike, enemy HP: " .. world.enemies[1].hp)

-- Check that Panache triggered (enemy took damage from 5 Strikes + Panache)
-- 5 Strikes = 5 * 6 = 30 damage
-- Panache = 10 damage
-- Total = 40 damage
local expectedDamage = (5 * 6) + 10  -- 5 strikes at 6 damage each, plus Panache 10
assert(world.enemies[1].hp == 100 - expectedDamage, "Enemy should take " .. expectedDamage .. " damage total (got " .. (100 - world.enemies[1].hp) .. ")")

print("✓ Test 1 passed: Panache triggered on 5th card\n")

-- Test 2: Panache triggers again on 10th card
print("Test 2: Panache triggers again on 10th card")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER",
    maxEnergy = 20
})

panache = Utils.deepCopyCard(Cards.Panache)
panache.state = "HAND"

strikes = {}
for i = 1, 10 do
    local strike = Utils.deepCopyCard(Cards.Strike)
    strike.state = "HAND"
    table.insert(strikes, strike)
end

world.player.masterDeck = {panache}
for _, strike in ipairs(strikes) do
    table.insert(world.player.masterDeck, strike)
end
world.player.combatDeck = Utils.deepCopyTable(world.player.masterDeck)

world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
world.enemies[1].hp = 200
world.enemies[1].maxHp = 200

StartCombat.execute(world)

-- Play Panache
playCard(world, world.player, panache)

-- Play 10 Strikes - should trigger Panache twice (at 5th and 10th card)
for i = 1, 10 do
    playCard(world, world.player, strikes[i])
end

-- 10 Strikes = 10 * 6 = 60 damage
-- Panache triggers twice (at 5th and 10th card) = 2 * 10 = 20 damage
-- Total = 80 damage
local expectedDamage2 = (10 * 6) + (2 * 10)
assert(world.enemies[1].hp == 200 - expectedDamage2, "Enemy should take " .. expectedDamage2 .. " damage total (got " .. (200 - world.enemies[1].hp) .. ")")

print("✓ Test 2 passed: Panache triggered on both 5th and 10th card\n")

-- Test 3: Upgraded Panache deals 14 damage
print("Test 3: Upgraded Panache deals 14 damage")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER",
    maxEnergy = 10
})

panache = Utils.deepCopyCard(Cards.Panache)
panache:onUpgrade()
panache.upgraded = true
panache.state = "HAND"

strikes = {}
for i = 1, 5 do
    local strike = Utils.deepCopyCard(Cards.Strike)
    strike.state = "HAND"
    table.insert(strikes, strike)
end

world.player.masterDeck = {panache}
for _, strike in ipairs(strikes) do
    table.insert(world.player.masterDeck, strike)
end
world.player.combatDeck = Utils.deepCopyTable(world.player.masterDeck)

world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
world.enemies[1].hp = 100
world.enemies[1].maxHp = 100

StartCombat.execute(world)

-- Play upgraded Panache
playCard(world, world.player, panache)
assert(world.player.status.panache == 14, "Upgraded Panache damage should be 14")
print("Upgraded Panache power applied: " .. world.player.status.panache .. " damage")

-- Play 5 Strikes
for i = 1, 5 do
    playCard(world, world.player, strikes[i])
end

-- 5 Strikes = 5 * 6 = 30 damage
-- Panache = 14 damage
-- Total = 44 damage
local expectedDamage3 = (5 * 6) + 14
assert(world.enemies[1].hp == 100 - expectedDamage3, "Enemy should take " .. expectedDamage3 .. " damage total (got " .. (100 - world.enemies[1].hp) .. ")")

print("✓ Test 3 passed: Upgraded Panache deals 14 damage\n")

-- Test 4: Panache affects ALL enemies
print("Test 4: Panache affects ALL enemies")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER",
    maxEnergy = 10
})

panache = Utils.deepCopyCard(Cards.Panache)
panache.state = "HAND"

strikes = {}
for i = 1, 5 do
    local strike = Utils.deepCopyCard(Cards.Strike)
    strike.state = "HAND"
    table.insert(strikes, strike)
end

world.player.masterDeck = {panache}
for _, strike in ipairs(strikes) do
    table.insert(world.player.masterDeck, strike)
end
world.player.combatDeck = Utils.deepCopyTable(world.player.masterDeck)

-- Create 3 enemies
world.enemies = {
    Utils.copyEnemyTemplate(Enemies.Cultist),
    Utils.copyEnemyTemplate(Enemies.Cultist),
    Utils.copyEnemyTemplate(Enemies.Cultist)
}
for _, enemy in ipairs(world.enemies) do
    enemy.hp = 100
    enemy.maxHp = 100
end

StartCombat.execute(world)

-- Play Panache
playCard(world, world.player, panache)

-- Play 5 Strikes targeting first enemy
for i = 1, 5 do
    playCard(world, world.player, strikes[i])
end

-- First enemy takes 5 Strikes = 30 damage
-- All 3 enemies take Panache = 10 damage each
-- First enemy: 30 + 10 = 40 damage
-- Other enemies: 10 damage each
assert(world.enemies[1].hp == 100 - 40, "First enemy should take 40 damage")
assert(world.enemies[2].hp == 100 - 10, "Second enemy should take 10 damage from Panache")
assert(world.enemies[3].hp == 100 - 10, "Third enemy should take 10 damage from Panache")

print("✓ Test 4 passed: Panache affects all enemies\n")

print("=== All Panache Tests Passed ===")
