-- Test for Vault card and End of Round mechanics
--
-- This test verifies:
-- 1. EndRound pipeline correctly ticks down status effects for all combatants
-- 2. Vault skips enemies' turns and EndRound phase
-- 3. Status effects persist through Vault (don't tick down)

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local EndTurn = require("Pipelines.EndTurn")
local EndRound = require("Pipelines.EndRound")
local EnemyTakeTurn = require("Pipelines.EnemyTakeTurn")
local StartTurn = require("Pipelines.StartTurn")
local ApplyStatusEffect = require("Pipelines.ApplyStatusEffect")

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

local function findCardById(deck, cardId)
    for _, card in ipairs(deck) do
        if card.id == cardId then
            return card
        end
    end
    error("Card " .. cardId .. " not found in deck")
end

print("=== Test 1: EndRound ticks down status effects ===")

-- Setup world with player and enemy, both with status effects
local deck1 = {
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend)
}

local world1 = World.createWorld({
    id = "Watcher",
    maxHp = 80,
    cards = deck1,
    relics = {}
})

world1.enemies = {
    copyEnemy(Enemies.Goblin)
}

StartCombat.execute(world1)

local player1 = world1.player
local enemy1 = world1.enemies[1]

-- Apply status effects to both player and enemy
player1.status.vulnerable = 3
player1.status.weak = 2
player1.status.frail = 1
player1.status.blur = 1
player1.status.intangible = 2

enemy1.status.vulnerable = 3
enemy1.status.weak = 2
enemy1.status.frail = 1
enemy1.status.intangible = 2

print("Before EndRound:")
print("  Player: vulnerable=" .. (player1.status.vulnerable or 0) .. " weak=" .. (player1.status.weak or 0) .. " frail=" .. (player1.status.frail or 0) .. " blur=" .. (player1.status.blur or 0) .. " intangible=" .. (player1.status.intangible or 0))
print("  Enemy: vulnerable=" .. (enemy1.status.vulnerable or 0) .. " weak=" .. (enemy1.status.weak or 0) .. " frail=" .. (enemy1.status.frail or 0) .. " intangible=" .. (enemy1.status.intangible or 0))

-- Execute EndRound
EndRound.execute(world1, player1, world1.enemies)

print("After EndRound:")
print("  Player: vulnerable=" .. (player1.status.vulnerable or 0) .. " weak=" .. (player1.status.weak or 0) .. " frail=" .. (player1.status.frail or 0) .. " blur=" .. (player1.status.blur or 0) .. " intangible=" .. (player1.status.intangible or 0))
print("  Enemy: vulnerable=" .. (enemy1.status.vulnerable or 0) .. " weak=" .. (enemy1.status.weak or 0) .. " frail=" .. (enemy1.status.frail or 0) .. " intangible=" .. (enemy1.status.intangible or 0))

-- Verify status effects decreased by 1 (or 0 for blur)
assert((player1.status.vulnerable or 0) == 2, "Player vulnerable should decrease by 1")
assert((player1.status.weak or 0) == 1, "Player weak should decrease by 1")
assert((player1.status.frail or 0) == 0, "Player frail should decrease by 1")
assert((player1.status.blur or 0) == 0, "Player blur should wear off")
assert((player1.status.intangible or 0) == 1, "Player intangible should decrease by 1")

assert((enemy1.status.vulnerable or 0) == 2, "Enemy vulnerable should decrease by 1")
assert((enemy1.status.weak or 0) == 1, "Enemy weak should decrease by 1")
assert((enemy1.status.frail or 0) == 0, "Enemy frail should decrease by 1")
assert((enemy1.status.intangible or 0) == 1, "Enemy intangible should decrease by 1")

print("✓ Test 1 passed: EndRound correctly ticks down status effects\n")

print("=== Test 2: Vault skips enemies' turns and EndRound ===")

-- Setup world with Vault card
local deck2 = {
    copyCard(Cards.Vault),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend)
}

local world2 = World.createWorld({
    id = "Watcher",
    maxHp = 80,
    cards = deck2,
    relics = {}
})

world2.enemies = {
    copyEnemy(Enemies.Goblin)
}

-- Enable NoShuffle so Vault (first card) is guaranteed to be in initial draw
world2.NoShuffle = true

StartCombat.execute(world2)

local player2 = world2.player
local enemy2 = world2.enemies[1]

-- Apply status effects
player2.status.vulnerable = 3
player2.status.weak = 2
enemy2.status.vulnerable = 3
enemy2.status.weak = 2
enemy2.block = 5  -- Enemy has block

-- Get initial hand size
local initialHandSize = 0
for _, card in ipairs(player2.combatDeck) do
    if card.state == "HAND" then
        initialHandSize = initialHandSize + 1
    end
end

print("Before Vault:")
print("  Player: vulnerable=" .. (player2.status.vulnerable or 0) .. " weak=" .. (player2.status.weak or 0))
print("  Enemy: vulnerable=" .. (enemy2.status.vulnerable or 0) .. " weak=" .. (enemy2.status.weak or 0) .. " block=" .. enemy2.block)
print("  Hand size: " .. initialHandSize)

-- Play Vault
local vaultCard = findCardById(player2.combatDeck, "Vault")
assert(vaultCard.state == "HAND", "Vault should be in hand")

-- Set the flag manually since we're not using CombatEngine's playGame loop
PlayCard.execute(world2, player2, vaultCard)
assert(world2.combat.vaultPlayed == true, "vaultPlayed flag should be set")

-- Simulate what CombatEngine does when Vault is played
world2.combat.vaultPlayed = nil
EndTurn.execute(world2, player2)
-- Skip enemy turns (normally would call EnemyTakeTurn here)
-- Skip EndRound (normally would call EndRound here)
StartTurn.execute(world2, player2)

print("After Vault:")
print("  Player: vulnerable=" .. (player2.status.vulnerable or 0) .. " weak=" .. (player2.status.weak or 0))
print("  Enemy: vulnerable=" .. (enemy2.status.vulnerable or 0) .. " weak=" .. (enemy2.status.weak or 0) .. " block=" .. enemy2.block)

-- Get new hand size
local newHandSize = 0
for _, card in ipairs(player2.combatDeck) do
    if card.state == "HAND" then
        newHandSize = newHandSize + 1
    end
end
print("  Hand size: " .. newHandSize)

-- Verify status effects did NOT decrease (EndRound was skipped)
assert((player2.status.vulnerable or 0) == 3, "Player vulnerable should NOT decrease (EndRound skipped)")
assert((player2.status.weak or 0) == 2, "Player weak should NOT decrease (EndRound skipped)")
assert((enemy2.status.vulnerable or 0) == 3, "Enemy vulnerable should NOT decrease (EndRound skipped)")
assert((enemy2.status.weak or 0) == 2, "Enemy weak should NOT decrease (EndRound skipped)")

-- Verify enemy block did NOT reset (enemy turn skipped)
assert(enemy2.block == 5, "Enemy block should NOT reset (enemy turn skipped)")

-- Verify player drew new hand
assert(newHandSize == 5, "Player should draw 5 cards after Vault")

-- Verify Vault was discarded
assert(vaultCard.state == "DISCARD_PILE", "Vault should be in discard pile")

print("✓ Test 2 passed: Vault correctly skips enemies' turns and EndRound\n")

print("=== Test 3: Normal end turn (without Vault) ===")

-- Setup world for normal turn end
local deck3 = {
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend),
    copyCard(Cards.Defend)
}

local world3 = World.createWorld({
    id = "Watcher",
    maxHp = 80,
    cards = deck3,
    relics = {}
})

world3.enemies = {
    copyEnemy(Enemies.Goblin)
}

StartCombat.execute(world3)

local player3 = world3.player
local enemy3 = world3.enemies[1]

-- Apply status effects
player3.status.vulnerable = 3
player3.status.weak = 2
enemy3.status.vulnerable = 3
enemy3.status.weak = 2
enemy3.block = 5

print("Before normal turn end:")
print("  Player: vulnerable=" .. (player3.status.vulnerable or 0) .. " weak=" .. (player3.status.weak or 0))
print("  Enemy: vulnerable=" .. (enemy3.status.vulnerable or 0) .. " weak=" .. (enemy3.status.weak or 0) .. " block=" .. enemy3.block)

-- Simulate normal turn end
EndTurn.execute(world3, player3)
EnemyTakeTurn.execute(world3, enemy3, player3)
EndRound.execute(world3, player3, world3.enemies)
StartTurn.execute(world3, player3)

print("After normal turn end:")
print("  Player: vulnerable=" .. (player3.status.vulnerable or 0) .. " weak=" .. (player3.status.weak or 0))
print("  Enemy: vulnerable=" .. (enemy3.status.vulnerable or 0) .. " weak=" .. (enemy3.status.weak or 0) .. " block=" .. enemy3.block)

-- Verify status effects DID decrease (EndRound was called)
assert((player3.status.vulnerable or 0) == 2, "Player vulnerable should decrease by 1")
assert((player3.status.weak or 0) == 1, "Player weak should decrease by 1")
assert((enemy3.status.vulnerable or 0) == 2, "Enemy vulnerable should decrease by 1")
assert((enemy3.status.weak or 0) == 1, "Enemy weak should decrease by 1")

-- Verify enemy block DID reset (enemy turn executed)
assert(enemy3.block == 0, "Enemy block should reset to 0")

print("✓ Test 3 passed: Normal turn end correctly processes all phases\n")

print("=== All Vault and EndRound tests passed! ===")
