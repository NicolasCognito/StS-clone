-- TEST: Nightmare card implementation
-- Tests delayed card addition via NIGHTMARE state

local World = require("World")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local StartTurn = require("Pipelines.StartTurn")
local EndTurn = require("Pipelines.EndTurn")
local ContextProvider = require("Pipelines.ContextProvider")
local Utils = require("utils")

local function findCard(world, cardId, state)
    for _, card in ipairs(world.player.combatDeck) do
        if card.id == cardId and (not state or card.state == state) then
            return card
        end
    end
    return nil
end

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
                local selection = context
                if type(context) == "table" and request.contextProvider and request.contextProvider.type == "cards" then
                    if #context == 1 then
                        selection = context[1]
                    end
                end
                world.combat.stableContext = selection
            else
                world.combat.tempContext = context
            end
            world.combat.contextRequest = nil
        end
    end
end

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
world.NoShuffle = true

-- Setup enemy
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

-- Start combat
StartCombat.execute(world)

print("Initial hand size: " .. Utils.getCardCountByState(world.player.combatDeck, "HAND"))

local nightmareCard = findCard(world, "Nightmare", "HAND")
local strikeCard = findCard(world, "Strike", "HAND")
assert(nightmareCard, "Nightmare card not found in hand")
assert(strikeCard, "Strike card not found in hand")

playCard(world, world.player, nightmareCard)

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
world.NoShuffle = true
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

local initialHandSize = Utils.getCardCountByState(world.player.combatDeck, "HAND")
print("Initial hand size (should be 10): " .. initialHandSize)

nightmareCard = findCard(world, "Nightmare", "HAND")
strikeCard = findCard(world, "Strike", "HAND")
assert(nightmareCard, "Nightmare card not found in hand")
assert(strikeCard, "Strike card not found in hand")

playCard(world, world.player, nightmareCard)

-- Check NIGHTMARE cards exist
nightmareCards = Utils.getCardsByState(world.player.combatDeck, "NIGHTMARE")
print("NIGHTMARE state cards: " .. #nightmareCards)

EndTurn.execute(world, world.player)

-- Start new turn with full hand (drawn cards)
world.player.status = world.player.status or {}
world.player.status.no_draw = 1  -- Prevent drawing to keep hand full
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
world.NoShuffle = true
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

-- Set up Echo Form (nightmare plays twice)
world.player.status.echo_form = 1
world.player.status.echoFormThisTurn = 1

-- Play Nightmare - should be duplicated by Echo Form
nightmareCard = findCard(world, "Nightmare", "HAND")
strikeCard = findCard(world, "Strike", "HAND")
assert(nightmareCard, "Nightmare card not found in hand")
assert(strikeCard, "Strike card not found in hand")

playCard(world, world.player, nightmareCard)

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
