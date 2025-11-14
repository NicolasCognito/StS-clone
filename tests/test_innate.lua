-- TEST: Innate keyword functionality
-- Tests that Innate cards always start in opening hand
-- and that draw calculation works correctly with many Innate cards

local World = require("World")
local Utils = require("utils")
local StartCombat = require("Pipelines.StartCombat")
local StartTurn = require("Pipelines.StartTurn")
local EndTurn = require("Pipelines.EndTurn")

math.randomseed(1337)

print("=== Testing Innate Keyword ===\n")

-- Helper to create a simple card
local function createCard(id, innate)
    return {
        id = id,
        name = id,
        cost = 0,
        type = "SKILL",
        innate = innate or false,
        onPlay = function() end
    }
end

-- Helper to count cards in hand
local function countCardsInHand(deck)
    local count = 0
    for _, card in ipairs(deck) do
        if card.state == "HAND" then
            count = count + 1
        end
    end
    return count
end

-- Helper to check if card is in hand
local function isCardInHand(deck, cardId)
    for _, card in ipairs(deck) do
        if card.state == "HAND" and card.id == cardId then
            return true
        end
    end
    return false
end

-- Test 1: Basic Innate - 1 Innate card with base draw
print("Test 1: Basic Innate (1 Innate card)")
local world1 = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    maxEnergy = 3,
    cards = {
        createCard("Innate1", true),
        createCard("Regular1"),
        createCard("Regular2"),
        createCard("Regular3"),
        createCard("Regular4"),
        createCard("Regular5"),
    }
})

world1.enemies = {Utils.copyEnemyTemplate({id = "TestEnemy", hp = 50, maxHp = 50})}
world1.NoShuffle = true
StartCombat.execute(world1)

local handSize1 = countCardsInHand(world1.player.combatDeck)
local hasInnate1 = isCardInHand(world1.player.combatDeck, "Innate1")

assert(handSize1 == 5, "Should draw 5 cards, got " .. handSize1)
assert(hasInnate1, "Innate1 should be in hand")
print("✓ Drew 5 cards with Innate1 in hand")
print()

-- Test 2: Multiple Innate cards (6 Innate, exceeds base draw)
print("Test 2: Multiple Innate cards (6 Innate > 5 base)")
local world2 = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    maxEnergy = 3,
    cards = {
        createCard("Innate1", true),
        createCard("Innate2", true),
        createCard("Innate3", true),
        createCard("Innate4", true),
        createCard("Innate5", true),
        createCard("Innate6", true),
        createCard("Regular1"),
        createCard("Regular2"),
    }
})

world2.enemies = {Utils.copyEnemyTemplate({id = "TestEnemy", hp = 50, maxHp = 50})}
world2.NoShuffle = true
StartCombat.execute(world2)

local handSize2 = countCardsInHand(world2.player.combatDeck)
assert(handSize2 == 6, "Should draw all 6 Innate cards, got " .. handSize2)

-- Check all 6 Innate cards are in hand
for i = 1, 6 do
    assert(isCardInHand(world2.player.combatDeck, "Innate" .. i), "Innate" .. i .. " should be in hand")
end
print("✓ Drew all 6 Innate cards")
print()

-- Test 3: More than 10 Innate cards (should cap at 10)
print("Test 3: More than 10 Innate cards (should cap at 10)")
local world3 = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    maxEnergy = 3,
    cards = {}
})

-- Add 12 Innate cards
for i = 1, 12 do
    table.insert(world3.player.masterDeck, createCard("Innate" .. i, true))
end
-- Add some regular cards
for i = 1, 3 do
    table.insert(world3.player.masterDeck, createCard("Regular" .. i))
end

world3.enemies = {Utils.copyEnemyTemplate({id = "TestEnemy", hp = 50, maxHp = 50})}
world3.NoShuffle = true
StartCombat.execute(world3)

local handSize3 = countCardsInHand(world3.player.combatDeck)
assert(handSize3 == 10, "Should cap at 10 cards, got " .. handSize3)

-- Count how many Innate cards are still in deck
local innateInDeck = 0
for _, card in ipairs(world3.player.combatDeck) do
    if card.state == "DECK" and card.innate then
        innateInDeck = innateInDeck + 1
    end
end
assert(innateInDeck == 2, "Should have 2 Innate cards left in deck, got " .. innateInDeck)
print("✓ Drew 10 cards (capped), 2 Innate cards remain in deck")
print()

-- Test 4: Innate only applies on first turn
print("Test 4: Innate only applies on first turn")
local world4 = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    maxEnergy = 3,
    cards = {
        createCard("Innate1", true),
        createCard("Innate2", true),
        createCard("Regular1"),
        createCard("Regular2"),
        createCard("Regular3"),
        createCard("Regular4"),
        createCard("Regular5"),
        createCard("Regular6"),
        createCard("Regular7"),
        createCard("Regular8"),
    }
})

world4.enemies = {Utils.copyEnemyTemplate({id = "TestEnemy", hp = 50, maxHp = 50})}
world4.NoShuffle = true
StartCombat.execute(world4)

-- First turn should draw 5 cards (2 Innate < 5 base, so normal draw)
local handSize4 = countCardsInHand(world4.player.combatDeck)
assert(handSize4 == 5, "First turn: should draw 5 cards, got " .. handSize4)
assert(isCardInHand(world4.player.combatDeck, "Innate1"), "Innate1 should be in hand")
assert(isCardInHand(world4.player.combatDeck, "Innate2"), "Innate2 should be in hand")

-- End turn (discard hand)
EndTurn.execute(world4, world4.player)

-- Second turn - Innate shouldn't have special positioning
StartTurn.execute(world4, world4.player)
local handSize4_turn2 = countCardsInHand(world4.player.combatDeck)
assert(handSize4_turn2 == 5, "Second turn: should draw 5 cards, got " .. handSize4_turn2)
print("✓ Innate only applies on first turn")
print()

-- Test 5: Backstab card
print("Test 5: Backstab card (Innate, Exhaust, Attack)")
local Cards = require("Data.cards")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")

local world5 = World.createWorld({
    id = "Silent",
    maxHp = 70,
    maxEnergy = 3,
    cards = {
        Utils.copyCardTemplate(Cards.Backstab),
        Utils.copyCardTemplate(Cards.Strike),
        Utils.copyCardTemplate(Cards.Strike),
        Utils.copyCardTemplate(Cards.Defend),
        Utils.copyCardTemplate(Cards.Defend),
    }
})

world5.enemies = {Utils.copyEnemyTemplate({id = "TestEnemy", hp = 50, maxHp = 50})}
world5.NoShuffle = true
StartCombat.execute(world5)

-- Check Backstab is in hand
local backstabInHand = false
local backstabCard = nil
for _, card in ipairs(world5.player.combatDeck) do
    if card.state == "HAND" and card.id == "Backstab" then
        backstabInHand = true
        backstabCard = card
        break
    end
end

assert(backstabInHand, "Backstab should be in starting hand (Innate)")
assert(backstabCard.innate == true, "Backstab should have innate property")
assert(backstabCard.exhausts == true, "Backstab should exhaust")
assert(backstabCard.damage == 11, "Backstab should deal 11 damage")
print("✓ Backstab has Innate property and is in starting hand")

-- Play Backstab
local function playCardWithAutoContext(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            return true
        elseif result == false then
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
                world.combat.tempContext = context
            end
            world.combat.contextRequest = nil
        end
    end
end

local initialEnemyHp = world5.enemies[1].hp
playCardWithAutoContext(world5, world5.player, backstabCard)

assert(world5.enemies[1].hp == initialEnemyHp - 11, "Backstab should deal 11 damage")
assert(backstabCard.state == "EXHAUSTED_PILE", "Backstab should be exhausted")
print("✓ Backstab deals 11 damage and exhausts")
print()

print("=== All Innate tests passed! ===")
