-- TEST: Master Reality power implementation
-- Tests auto-upgrade of created cards

local World = require("World")
local Cards = require("Data.cards")
local Powers = require("Data.powers")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local AcquireCard = require("Pipelines.AcquireCard")
local StartTurn = require("Pipelines.StartTurn")
local EndTurn = require("Pipelines.EndTurn")
local Utils = require("utils")

print("=== Testing Master Reality Power ===\n")

-- Test 1: Master Reality with AcquireCard pipeline
print("Test 1: Master Reality auto-upgrades via AcquireCard")
local world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER"
})

world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
StartCombat.execute(world)

-- Apply Master Reality status effect
world.player.status.master_reality = 1

-- Acquire a Strike (should be auto-upgraded)
local acquiredCard = AcquireCard.execute(world, world.player, Cards.Strike, nil, "combat")

print("Acquired card: " .. acquiredCard.name)
print("Is upgraded: " .. tostring(acquiredCard.upgraded))
print("Damage: " .. (acquiredCard.damage or "N/A"))

assert(acquiredCard.upgraded == true, "Acquired card should be upgraded with Master Reality")
assert(acquiredCard.damage == 8, "Upgraded Strike should deal 8 damage (was " .. acquiredCard.damage .. ")")

print("✓ Test 1 passed: AcquireCard respects Master Reality\n")

-- Test 2: Master Reality with Nightmare
print("Test 2: Master Reality auto-upgrades Nightmare copies")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER"
})

local nightmare = Utils.deepCopyCard(Cards.Nightmare)
nightmare.state = "HAND"

local strike = Utils.deepCopyCard(Cards.Strike)
strike.state = "HAND"
strike.upgraded = false  -- Ensure unupgraded
strike.damage = 6  -- Base damage

world.player.masterDeck = {nightmare, strike}
world.player.combatDeck = {nightmare, strike}
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

-- Apply Master Reality status effect
world.player.status.master_reality = 1

-- Play Nightmare on Strike
world.combat.stableContext = strike
PlayCard.execute(world, world.player, nightmare)

-- Check NIGHTMARE state cards
local nightmareCards = Utils.getCardsByState(world.player.combatDeck, "NIGHTMARE")
print("NIGHTMARE cards created: " .. #nightmareCards)

-- Verify all are upgraded
local allUpgraded = true
local allCorrectDamage = true
for _, card in ipairs(nightmareCards) do
    print("  Card: " .. card.name .. ", Upgraded: " .. tostring(card.upgraded) .. ", Damage: " .. card.damage)
    if not card.upgraded then
        allUpgraded = false
    end
    if card.damage ~= 8 then
        allCorrectDamage = false
    end
end

assert(allUpgraded, "All Nightmare copies should be upgraded with Master Reality")
assert(allCorrectDamage, "All upgraded Strike copies should deal 8 damage")

print("✓ Test 2 passed: Nightmare respects Master Reality\n")

-- Test 3: Master Reality only upgrades once (no double upgrade)
print("Test 3: Master Reality doesn't double-upgrade already upgraded cards")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER"
})

world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
StartCombat.execute(world)

-- Apply Master Reality status effect
world.player.status.master_reality = 1

-- Acquire an already-upgraded Strike
local upgradedStrike = Utils.deepCopyCard(Cards.Strike)
upgradedStrike:onUpgrade()
upgradedStrike.upgraded = true

local acquiredCard = AcquireCard.execute(world, world.player, upgradedStrike, nil, "combat")

print("Acquired upgraded card: " .. acquiredCard.name)
print("Damage: " .. acquiredCard.damage)

-- Strike upgraded once is 8 damage, if double-upgraded we'd see different behavior
assert(acquiredCard.damage == 8, "Should not double-upgrade already upgraded cards")

print("✓ Test 3 passed: No double-upgrade\n")

-- Test 4: Master Reality with cards that have no onUpgrade
print("Test 4: Master Reality gracefully handles cards without onUpgrade")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER"
})

world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
StartCombat.execute(world)

-- Apply Master Reality status effect
world.player.status.master_reality = 1

-- Create a card without onUpgrade function
local noUpgradeCard = {
    id = "NoUpgrade",
    name = "No Upgrade",
    cost = 1,
    type = "SKILL",
    upgraded = false
    -- No onUpgrade function
}

local acquiredCard = AcquireCard.execute(world, world.player, noUpgradeCard, nil, "combat")

print("Acquired card without onUpgrade: " .. acquiredCard.name)
print("Is upgraded: " .. tostring(acquiredCard.upgraded))

-- Should not crash, upgraded flag should remain false
assert(acquiredCard.upgraded == false, "Card without onUpgrade should remain unupgraded")

print("✓ Test 4 passed: Handles cards without onUpgrade\n")

print("=== All Master Reality Tests Passed ===")
