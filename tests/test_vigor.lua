-- TEST: Vigor Status Effect
-- Tests Vigor status that adds damage to next Attack and is consumed after use

local World = require("World")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local EndRound = require("Pipelines.EndRound")
local ContextProvider = require("Pipelines.ContextProvider")
local Utils = require("utils")
local StatusEffects = require("Data.StatusEffects.vigor")

print("=== Testing Vigor Status Effect ===\n")

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

-- Test 1: Vigor adds damage to Attack
print("Test 1: Vigor adds damage to Attack")
local world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "IRONCLAD",
    maxEnergy = 10
})

local strike = Utils.deepCopyCard(Cards.Strike)
strike.state = "HAND"

world.player.masterDeck = {strike}
world.player.combatDeck = Utils.deepCopyTable(world.player.masterDeck)

world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
world.enemies[1].hp = 100
world.enemies[1].maxHp = 100

StartCombat.execute(world)

-- Give player 5 Vigor
world.player.status.vigor = 5

-- Play Strike (6 base damage + 5 Vigor = 11 damage)
playCard(world, world.player, strike)

assert(world.enemies[1].hp == 89, "Enemy should take 11 damage (6 base + 5 Vigor), got " .. (100 - world.enemies[1].hp))
assert(world.player.status.vigor == 0 or not world.player.status.vigor, "Vigor should be consumed after Attack")
print("✓ Test 1 passed: Vigor adds damage to Attack and is consumed\n")

-- Test 2: Vigor applies to AOE attacks (each enemy gets the bonus)
print("Test 2: Vigor applies to AOE attacks")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "IRONCLAD",
    maxEnergy = 10
})

local whirlwind = Utils.deepCopyCard(Cards.Whirlwind)
whirlwind.state = "HAND"

world.player.masterDeck = {whirlwind}
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

-- Give player 10 Vigor and play Whirlwind (X=0, so 0 base damage + 10 Vigor per enemy)
world.player.status.vigor = 10
world.player.energy = 1  -- X=1, so 1 hit per enemy

playCard(world, world.player, whirlwind)

-- Each enemy should take 1 base damage + 10 Vigor = 11 damage
for i, enemy in ipairs(world.enemies) do
    assert(enemy.hp == 89, "Enemy " .. i .. " should take 11 damage, got " .. (100 - enemy.hp))
end
assert(world.player.status.vigor == 0 or not world.player.status.vigor, "Vigor should be consumed after Attack")
print("✓ Test 2 passed: Vigor applies to each enemy in AOE attack\n")

-- Test 3: Vigor does NOT expire at end of turn
print("Test 3: Vigor does NOT expire at end of turn")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "IRONCLAD",
    maxEnergy = 10
})

local defend = Utils.deepCopyCard(Cards.Defend)
defend.state = "HAND"

world.player.masterDeck = {defend}
world.player.combatDeck = Utils.deepCopyTable(world.player.masterDeck)

world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
world.enemies[1].hp = 100
world.enemies[1].maxHp = 100

StartCombat.execute(world)

-- Give player 8 Vigor
world.player.status.vigor = 8

-- Play Defend (non-Attack card)
playCard(world, world.player, defend)

assert(world.player.status.vigor == 8, "Vigor should not be consumed by non-Attack card")
print("Vigor after Defend: " .. world.player.status.vigor)

-- End turn
EndRound.execute(world, world.player)

-- Vigor should still be 8 (doesn't expire at end of turn)
assert(world.player.status.vigor == 8, "Vigor should NOT expire at end of turn, got " .. (world.player.status.vigor or 0))
print("✓ Test 3 passed: Vigor persists through end of turn\n")

-- Test 4: Vigor is consumed only AFTER Attack is played
print("Test 4: Vigor is consumed only AFTER Attack is played")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "IRONCLAD",
    maxEnergy = 10
})

strike = Utils.deepCopyCard(Cards.Strike)
strike.state = "HAND"
local strike2 = Utils.deepCopyCard(Cards.Strike)
strike2.state = "HAND"

world.player.masterDeck = {strike, strike2}
world.player.combatDeck = Utils.deepCopyTable(world.player.masterDeck)

world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
world.enemies[1].hp = 100
world.enemies[1].maxHp = 100

StartCombat.execute(world)

-- Give player 7 Vigor
world.player.status.vigor = 7

-- Play first Strike (6 base + 7 Vigor = 13 damage)
playCard(world, world.player, strike)
assert(world.enemies[1].hp == 87, "First Strike should deal 13 damage, got " .. (100 - world.enemies[1].hp))
assert(world.player.status.vigor == 0 or not world.player.status.vigor, "Vigor should be consumed after first Attack")

-- Play second Strike (6 base damage only, no Vigor)
playCard(world, world.player, strike2)
assert(world.enemies[1].hp == 81, "Second Strike should deal only 6 damage (no Vigor), got " .. (87 - world.enemies[1].hp))

print("✓ Test 4 passed: Vigor is consumed after first Attack\n")

-- Test 5: Vigor applies to multi-hit attacks (each hit)
print("Test 5: Vigor applies to multi-hit attacks")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "IRONCLAD",
    maxEnergy = 10
})

-- Use Whirlwind with X=2 to get 2 hits
whirlwind = Utils.deepCopyCard(Cards.Whirlwind)
whirlwind.state = "HAND"

world.player.masterDeck = {whirlwind}
world.player.combatDeck = Utils.deepCopyTable(world.player.masterDeck)

world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
world.enemies[1].hp = 100
world.enemies[1].maxHp = 100

StartCombat.execute(world)

-- Give player 5 Vigor and play Whirlwind with X=2 (2 hits)
world.player.status.vigor = 5
world.player.energy = 2  -- X=2

playCard(world, world.player, whirlwind)

-- Each hit should get Vigor bonus: 2 hits * (2 base + 5 Vigor) = 2 * 7 = 14 damage
assert(world.enemies[1].hp == 86, "Enemy should take 14 damage from 2 hits with Vigor, got " .. (100 - world.enemies[1].hp))
assert(world.player.status.vigor == 0 or not world.player.status.vigor, "Vigor should be consumed after Attack")
print("✓ Test 5 passed: Vigor applies to each hit in multi-hit attack\n")

print("=== All Vigor Tests Passed ===")
