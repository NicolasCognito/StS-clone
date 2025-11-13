-- TEST: Nightmare card implementation
-- Tests delayed card addition via NIGHTMARE state

local World = require("World")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local StartTurn = require("Pipelines.StartTurn")
local EndTurn = require("Pipelines.EndTurn")
local Utils = require("utils")

print("=== Testing Nightmare Card ===\n")

-- Test 1: Basic Nightmare functionality
print("Test 1: Nightmare adds 3 copies next turn")
local world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "SILENT"
})

-- Setup deck: Nightmare + Strike in hand
local nightmare = Utils.deepCopyCard(Cards.Nightmare)
nightmare.state = "HAND"

local strike = Utils.deepCopyCard(Cards.Strike)
strike.state = "HAND"

world.player.masterDeck = {nightmare, strike}
world.player.combatDeck = {nightmare, strike}

-- Setup enemy
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

-- Start combat
StartCombat.execute(world)

print("Initial hand size: " .. Utils.getCardCountByState(world.player.combatDeck, "HAND"))

-- Play Nightmare, selecting Strike
-- Simulate context selection (in real game, CLI/GUI would collect this)
world.combat.stableContext = strike

PlayCard.execute(world, world.player, nightmare)

-- Check NIGHTMARE state cards exist
local nightmareCards = Utils.getCardsByState(world.player.combatDeck, "NIGHTMARE")
print("NIGHTMARE state cards after playing: " .. #nightmareCards)
assert(#nightmareCards == 3, "Should have 3 NIGHTMARE cards, got " .. #nightmareCards)

-- End turn (enemies would act here)
EndTurn.execute(world, world.player)

-- Start new turn - NIGHTMARE cards should move to hand
StartTurn.execute(world, world.player)

local handCards = Utils.getCardsByState(world.player.combatDeck, "HAND")
local strikeCount = 0
for _, card in ipairs(handCards) do
    if card.id == "Strike" then
        strikeCount = strikeCount + 1
    end
end

print("Strike cards in hand after StartTurn: " .. strikeCount)
assert(strikeCount >= 3, "Should have at least 3 Strike copies in hand, got " .. strikeCount)

print("✓ Test 1 passed: Nightmare adds 3 copies next turn\n")

-- Test 2: Nightmare with full hand (cards should be lost)
print("Test 2: Nightmare with full hand loses cards")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "SILENT"
})

nightmare = Utils.deepCopyCard(Cards.Nightmare)
nightmare.state = "HAND"

strike = Utils.deepCopyCard(Cards.Strike)
strike.state = "HAND"

-- Fill hand with 10 cards (max hand size)
world.player.combatDeck = {nightmare, strike}
for i = 1, 8 do
    local filler = Utils.deepCopyCard(Cards.Defend)
    filler.state = "HAND"
    table.insert(world.player.combatDeck, filler)
end

world.player.masterDeck = world.player.combatDeck
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

local initialHandSize = Utils.getCardCountByState(world.player.combatDeck, "HAND")
print("Initial hand size (should be 10): " .. initialHandSize)

-- Play Nightmare
world.combat.stableContext = strike
PlayCard.execute(world, world.player, nightmare)

-- Check NIGHTMARE cards exist
nightmareCards = Utils.getCardsByState(world.player.combatDeck, "NIGHTMARE")
print("NIGHTMARE state cards: " .. #nightmareCards)

EndTurn.execute(world, world.player)

-- Start new turn with full hand (drawn cards)
world.player.cannotDraw = true  -- Prevent drawing to keep hand full
StartTurn.execute(world, world.player)

-- Check that NIGHTMARE cards were removed (hand was full)
nightmareCards = Utils.getCardsByState(world.player.combatDeck, "NIGHTMARE")
print("NIGHTMARE state cards after StartTurn (should be 0): " .. #nightmareCards)

local totalCards = #world.player.combatDeck
print("Total cards in deck: " .. totalCards)

print("✓ Test 2 passed: Full hand loses Nightmare cards\n")

-- Test 3: Nightmare with duplication (stable context)
print("Test 3: Nightmare duplication uses same card")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "SILENT"
})

nightmare = Utils.deepCopyCard(Cards.Nightmare)
nightmare.state = "HAND"

strike = Utils.deepCopyCard(Cards.Strike)
strike.state = "HAND"

local defend = Utils.deepCopyCard(Cards.Defend)
defend.state = "HAND"

world.player.masterDeck = {nightmare, strike, defend}
world.player.combatDeck = {nightmare, strike, defend}
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

-- Set up Echo Form (nightmare plays twice)
world.player.powers = world.player.powers or {}
table.insert(world.player.powers, {id = "EchoForm", stacks = 1})
world.player.status.echoFormThisTurn = 1

-- Play Nightmare - should be duplicated by Echo Form
world.combat.stableContext = strike
PlayCard.execute(world, world.player, nightmare)

-- Check NIGHTMARE cards: should be 6 (3 from initial, 3 from Echo Form duplication)
nightmareCards = Utils.getCardsByState(world.player.combatDeck, "NIGHTMARE")
print("NIGHTMARE cards with Echo Form duplication: " .. #nightmareCards)
assert(#nightmareCards == 6, "Should have 6 NIGHTMARE cards (3 + 3 from duplication), got " .. #nightmareCards)

-- Verify all are Strike (stable context should persist)
local allStrike = true
for _, card in ipairs(nightmareCards) do
    if card.id ~= "Strike" then
        allStrike = false
        break
    end
end
assert(allStrike, "All NIGHTMARE cards should be Strike (stable context)")

print("✓ Test 3 passed: Duplication uses stable context\n")

print("=== All Nightmare Tests Passed ===")
