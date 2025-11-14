-- TEST: AcquireCard Pipeline
-- Tests the redesigned AcquireCard with filtering, destinations, and options

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local StartCombat = require("Pipelines.StartCombat")
local AcquireCard = require("Pipelines.AcquireCard")

math.randomseed(1337)

local function countCardsInState(deck, state)
    local count = 0
    for _, card in ipairs(deck) do
        if card.state == state then
            count = count + 1
        end
    end
    return count
end

local function findCardsByName(deck, name)
    local cards = {}
    for _, card in ipairs(deck) do
        if card.name == name then
            table.insert(cards, card)
        end
    end
    return cards
end

print("=== TEST 1: Simple card to hand (3 Shivs) ===")
do
    local world = World.createWorld({
        id = "Silent",
        maxHp = 70,
        cards = {},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(require("Data.enemies").Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local initialHandSize = countCardsInState(world.player.combatDeck, "HAND")

    -- Acquire 3 Shivs to hand
    local created = AcquireCard.execute(world, world.player, Cards.Shiv, {
        destination = "HAND",
        count = 3
    })

    assert(#created == 3, "Should create 3 cards")
    assert(created[1].name == "Shiv", "Should be Shiv")

    local newHandSize = countCardsInState(world.player.combatDeck, "HAND")
    assert(newHandSize == initialHandSize + 3, "Hand should have 3 more cards")

    print("✓ Simple card to hand works")
end

print("\n=== TEST 2: Card to hand with costsZeroThisTurn tag ===")
do
    local world = World.createWorld({
        id = "Ironclad",
        maxHp = 80,
        cards = {},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(require("Data.enemies").Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Acquire random Attack with costsZeroThisTurn
    local created = AcquireCard.execute(world, world.player, {
        filter = function(world, card)
            return card.type == "ATTACK" and card.character == "IRONCLAD"
        end,
        count = 1
    }, {
        destination = "HAND",
        tags = {"costsZeroThisTurn"}
    })

    assert(#created == 1, "Should create 1 card")
    assert(created[1].type == "ATTACK", "Should be an Attack")
    assert(created[1].costsZeroThisTurn == 1, "Should have costsZeroThisTurn tag")

    print("✓ Card with tag works: " .. created[1].name)
end

print("\n=== TEST 3: Card to discard pile ===")
do
    local world = World.createWorld({
        id = "Ironclad",
        maxHp = 80,
        cards = {},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(require("Data.enemies").Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local initialDiscardSize = countCardsInState(world.player.combatDeck, "DISCARD_PILE")

    -- Acquire Burn to discard pile
    local created = AcquireCard.execute(world, world.player, Cards.Burn, {
        destination = "DISCARD_PILE"
    })

    assert(#created == 1, "Should create 1 card")
    assert(created[1].state == "DISCARD_PILE", "Should be in discard pile")

    local newDiscardSize = countCardsInState(world.player.combatDeck, "DISCARD_PILE")
    assert(newDiscardSize == initialDiscardSize + 1, "Discard pile should have 1 more card")

    print("✓ Card to discard pile works")
end

print("\n=== TEST 4: Insert card into draw pile (NOT full shuffle) ===")
do
    local world = World.createWorld({
        id = "Ironclad",
        maxHp = 80,
        cards = {
            Utils.copyCardTemplate(Cards.Strike),
            Utils.copyCardTemplate(Cards.Strike),
            Utils.copyCardTemplate(Cards.Defend),
        },
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(require("Data.enemies").Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local initialDeckSize = countCardsInState(world.player.combatDeck, "DECK")

    -- Insert Wound into draw pile at random position
    local created = AcquireCard.execute(world, world.player, Cards.Wound, {
        destination = "DECK",
        position = "random"
    })

    assert(#created == 1, "Should create 1 card")
    assert(created[1].state == "DECK", "Should be in draw pile")

    local newDeckSize = countCardsInState(world.player.combatDeck, "DECK")
    assert(newDeckSize == initialDeckSize + 1, "Draw pile should have 1 more card")

    -- Verify the Wound is actually in the deck
    local wounds = findCardsByName(world.player.combatDeck, "Wound")
    assert(#wounds == 1, "Should have 1 Wound")
    assert(wounds[1].state == "DECK", "Wound should be in DECK state")

    print("✓ Insert into draw pile works")
end

print("\n=== TEST 5: Multiple random cards with filter (Discovery pattern) ===")
do
    local world = World.createWorld({
        id = "Ironclad",
        maxHp = 80,
        cards = {},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(require("Data.enemies").Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Acquire 3 different random cards to DRAFT state
    local created = AcquireCard.execute(world, world.player, {
        filter = function(world, card)
            return card.character and card.rarity ~= "CURSE"
        end,
        count = 3
    }, {
        destination = "DRAFT"
    })

    assert(#created == 3, "Should create 3 cards")

    for i, card in ipairs(created) do
        assert(card.state == "DRAFT", "Card " .. i .. " should have DRAFT state")
        assert(card.rarity ~= "CURSE", "Card " .. i .. " should not be a curse")
    end

    -- Verify all 3 are different cards
    local names = {}
    for _, card in ipairs(created) do
        assert(not names[card.id], "Cards should be unique: " .. card.id)
        names[card.id] = true
    end

    print("✓ Multiple random cards with filter works")
    print("  Created: " .. created[1].name .. ", " .. created[2].name .. ", " .. created[3].name)
end

print("\n=== TEST 6: Custom state (Nightmare pattern) ===")
do
    local world = World.createWorld({
        id = "Silent",
        maxHp = 70,
        cards = {},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(require("Data.enemies").Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Acquire 3 copies of Strike with NIGHTMARE state
    local created = AcquireCard.execute(world, world.player, Cards.Strike, {
        destination = "NIGHTMARE",
        count = 3
    })

    assert(#created == 3, "Should create 3 cards")

    for i, card in ipairs(created) do
        assert(card.state == "NIGHTMARE", "Card " .. i .. " should have NIGHTMARE state")
        assert(card.name == "Strike", "Card " .. i .. " should be Strike")
    end

    local nightmareCount = countCardsInState(world.player.combatDeck, "NIGHTMARE")
    assert(nightmareCount == 3, "Should have 3 NIGHTMARE cards")

    print("✓ Custom state (NIGHTMARE) works")
end

print("\n=== TEST 7: Master Reality auto-upgrade ===")
do
    local world = World.createWorld({
        id = "Ironclad",
        maxHp = 80,
        cards = {},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(require("Data.enemies").Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Give player Master Reality power
    world.player.status = world.player.status or {}
    world.player.status.master_reality = 1

    -- Acquire Strike (should be auto-upgraded)
    local created = AcquireCard.execute(world, world.player, Cards.Strike, {
        destination = "HAND"
    })

    assert(#created == 1, "Should create 1 card")
    assert(created[1].upgraded == true, "Strike should be upgraded by Master Reality")
    assert(created[1].damage == 9, "Upgraded Strike should deal 9 damage")

    print("✓ Master Reality auto-upgrade works")
end

print("\n=== TEST 8: Position options (top, bottom) ===")
do
    local world = World.createWorld({
        id = "Ironclad",
        maxHp = 80,
        cards = {
            Utils.copyCardTemplate(Cards.Strike),
            Utils.copyCardTemplate(Cards.Strike),
            Utils.copyCardTemplate(Cards.Strike),
        },
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(require("Data.enemies").Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Insert Wound at top of deck
    local created1 = AcquireCard.execute(world, world.player, Cards.Wound, {
        destination = "DECK",
        position = "top"
    })

    -- Insert Dazed at bottom of deck
    local created2 = AcquireCard.execute(world, world.player, Cards.Dazed, {
        destination = "DECK",
        position = "bottom"
    })

    -- Get all DECK cards in order
    local deckCards = {}
    for _, card in ipairs(world.player.combatDeck) do
        if card.state == "DECK" then
            table.insert(deckCards, card)
        end
    end

    assert(deckCards[1].name == "Wound", "First card should be Wound (top position)")
    assert(deckCards[#deckCards].name == "Dazed", "Last card should be Dazed (bottom position)")

    print("✓ Position options (top, bottom) work")
end

print("\n=== TEST 9: To master deck (permanent) ===")
do
    local world = World.createWorld({
        id = "Ironclad",
        maxHp = 80,
        cards = {},
        relics = {}
    })

    local initialMasterSize = #world.player.masterDeck

    -- Acquire card to master deck (out of combat)
    local created = AcquireCard.execute(world, world.player, Cards.Strike, {
        targetDeck = "master"
    })

    assert(#created == 1, "Should create 1 card")
    assert(#world.player.masterDeck == initialMasterSize + 1, "Master deck should grow")
    assert(world.player.masterDeck[#world.player.masterDeck].name == "Strike", "Strike added to master deck")

    print("✓ Master deck acquisition works")
end

print("\n=== ALL TESTS PASSED ===")
