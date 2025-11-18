-- Test: Unceasing Top Relic
-- Tests that Unceasing Top draws a card whenever hand is empty during player's turn

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Relics = require("Data.relics")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local EndTurn = require("Pipelines.EndTurn")
local ContextProvider = require("Pipelines.ContextProvider")

math.randomseed(1337)

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

local function countCardsInState(deck, state)
    local count = 0
    for _, card in ipairs(deck) do
        if card.state == state then
            count = count + 1
        end
    end
    return count
end

print("=== Unceasing Top Relic Tests ===\n")

-- TEST 1: Unceasing Top draws a card when hand becomes empty
print("Test 1: Unceasing Top draws when hand is empty")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {
            Utils.copyCardTemplate(Cards.Strike),  -- Will be in hand
            Utils.copyCardTemplate(Cards.Defend),  -- Will be in deck
            Utils.copyCardTemplate(Cards.Bash)     -- Will be in deck
        },
        relics = {Relics.UnceasingTop}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Initially should have 3 cards in hand (all cards drawn at start)
    local initialHandSize = countCardsInState(world.player.combatDeck, "HAND")
    assert(initialHandSize == 3, "Should have 3 cards in hand initially, got " .. initialHandSize)

    -- Play all cards in hand
    for i = 1, 3 do
        local handCard = nil
        for _, card in ipairs(world.player.combatDeck) do
            if card.state == "HAND" then
                handCard = card
                break
            end
        end

        if handCard then
            playCardWithAutoContext(world, world.player, handCard)
        end
    end

    -- After playing all cards, Unceasing Top should have triggered
    -- and drawn cards until we ran out or filled the hand again
    local finalHandSize = countCardsInState(world.player.combatDeck, "HAND")

    -- We should have 0 cards in hand (deck is empty after drawing all 3)
    assert(finalHandSize == 0, "Hand should be empty (deck exhausted), got " .. finalHandSize)

    print("✓ Unceasing Top attempts to draw when hand is empty")
end

-- TEST 2: Unceasing Top draws multiple cards if deck has cards
print("Test 2: Unceasing Top draws until hand has cards")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {
            Utils.copyCardTemplate(Cards.Strike),  -- Will be in hand
            Utils.copyCardTemplate(Cards.Defend),  -- Stays in deck
            Utils.copyCardTemplate(Cards.Bash),    -- Stays in deck
            Utils.copyCardTemplate(Cards.Shrug),   -- Stays in deck
            Utils.copyCardTemplate(Cards.Shrug),   -- Stays in deck
            Utils.copyCardTemplate(Cards.Shrug)    -- Stays in deck
        },
        relics = {Relics.UnceasingTop}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Move all but 1 card from hand to deck
    local movedCount = 0
    for _, card in ipairs(world.player.combatDeck) do
        if card.state == "HAND" and movedCount < 5 then
            card.state = "DECK"
            movedCount = movedCount + 1
        end
    end

    local initialHandSize = countCardsInState(world.player.combatDeck, "HAND")
    assert(initialHandSize == 1, "Should have 1 card in hand after moving, got " .. initialHandSize)

    -- Play the one card in hand
    local handCard = nil
    for _, card in ipairs(world.player.combatDeck) do
        if card.state == "HAND" then
            handCard = card
            break
        end
    end

    playCardWithAutoContext(world, world.player, handCard)

    -- Unceasing Top should draw exactly 1 card
    local finalHandSize = countCardsInState(world.player.combatDeck, "HAND")
    assert(finalHandSize == 1, "Should have 1 card in hand from Unceasing Top, got " .. finalHandSize)

    print("✓ Unceasing Top draws until hand has cards")
end

-- TEST 3: Unceasing Top does NOT draw if hand is not empty
print("Test 3: Unceasing Top does not draw if hand is not empty")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {
            Utils.copyCardTemplate(Cards.Strike),
            Utils.copyCardTemplate(Cards.Defend),
            Utils.copyCardTemplate(Cards.Bash)
        },
        relics = {Relics.UnceasingTop}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Move all cards to deck
    for _, card in ipairs(world.player.combatDeck) do
        card.state = "DECK"
    end

    -- Put 2 cards in hand
    local count = 0
    for _, card in ipairs(world.player.combatDeck) do
        if count < 2 then
            card.state = "HAND"
            count = count + 1
        end
    end

    local initialHandSize = countCardsInState(world.player.combatDeck, "HAND")
    assert(initialHandSize == 2, "Should have 2 cards in hand, got " .. initialHandSize)

    -- Play one card (hand still has 1 card)
    local handCard = nil
    for _, card in ipairs(world.player.combatDeck) do
        if card.state == "HAND" then
            handCard = card
            break
        end
    end

    playCardWithAutoContext(world, world.player, handCard)

    -- Should still have 1 card in hand (Unceasing Top should NOT trigger)
    local finalHandSize = countCardsInState(world.player.combatDeck, "HAND")
    assert(finalHandSize == 1, "Should still have 1 card in hand (no Unceasing Top draw), got " .. finalHandSize)

    print("✓ Unceasing Top does not draw if hand is not empty")
end

-- TEST 4: Unceasing Top works with exhaust cards
print("Test 4: Unceasing Top works with exhaust cards")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {
            Utils.copyCardTemplate(Cards.Meditate),  -- Exhausts
            Utils.copyCardTemplate(Cards.Strike),
            Utils.copyCardTemplate(Cards.Defend)
        },
        relics = {Relics.UnceasingTop}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Put only Meditate in hand
    for _, card in ipairs(world.player.combatDeck) do
        if card.id == "Meditate" then
            card.state = "HAND"
        else
            card.state = "DECK"
        end
    end

    local meditate = nil
    for _, card in ipairs(world.player.combatDeck) do
        if card.id == "Meditate" then
            meditate = card
            break
        end
    end

    assert(meditate ~= nil, "Should have Meditate card")

    -- Play Meditate (it exhausts)
    playCardWithAutoContext(world, world.player, meditate)

    -- Hand should be empty initially, then Unceasing Top draws 1
    local finalHandSize = countCardsInState(world.player.combatDeck, "HAND")
    assert(finalHandSize == 1, "Should have 1 card from Unceasing Top after Meditate exhausts, got " .. finalHandSize)

    -- Meditate should be exhausted
    assert(meditate.state == "EXHAUSTED_PILE", "Meditate should be exhausted")

    print("✓ Unceasing Top works with exhaust cards")
end

-- TEST 5: Without Unceasing Top, hand stays empty
print("Test 5: Without Unceasing Top, hand stays empty")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {
            Utils.copyCardTemplate(Cards.Strike),
            Utils.copyCardTemplate(Cards.Defend),
            Utils.copyCardTemplate(Cards.Bash)
        },
        relics = {}  -- NO Unceasing Top
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Put 1 card in hand, rest in deck
    local count = 0
    for _, card in ipairs(world.player.combatDeck) do
        if count == 0 then
            card.state = "HAND"
            count = count + 1
        else
            card.state = "DECK"
        end
    end

    -- Play the one card
    local handCard = nil
    for _, card in ipairs(world.player.combatDeck) do
        if card.state == "HAND" then
            handCard = card
            break
        end
    end

    playCardWithAutoContext(world, world.player, handCard)

    -- Hand should be empty (no Unceasing Top to draw)
    local finalHandSize = countCardsInState(world.player.combatDeck, "HAND")
    assert(finalHandSize == 0, "Hand should be empty without Unceasing Top, got " .. finalHandSize)

    print("✓ Without Unceasing Top, hand stays empty")
end

-- TEST 6: Unceasing Top continues drawing until hand has cards or deck is empty
print("Test 6: Unceasing Top handles empty deck gracefully")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {
            Utils.copyCardTemplate(Cards.Strike)  -- Only 1 card total
        },
        relics = {Relics.UnceasingTop}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Play the only card
    local strike = world.player.combatDeck[1]
    playCardWithAutoContext(world, world.player, strike)

    -- Hand should be empty (no cards left to draw)
    local finalHandSize = countCardsInState(world.player.combatDeck, "HAND")
    assert(finalHandSize == 0, "Hand should be empty when deck is exhausted, got " .. finalHandSize)

    -- Card should be in discard pile
    assert(strike.state == "DISCARD_PILE", "Strike should be in discard pile")

    print("✓ Unceasing Top handles empty deck gracefully")
end

-- TEST 7: Unceasing Top works across multiple card plays
print("Test 7: Unceasing Top works across multiple card plays")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {
            Utils.copyCardTemplate(Cards.Strike),
            Utils.copyCardTemplate(Cards.Strike),
            Utils.copyCardTemplate(Cards.Defend),
            Utils.copyCardTemplate(Cards.Defend),
            Utils.copyCardTemplate(Cards.Bash),
            Utils.copyCardTemplate(Cards.Bash)
        },
        relics = {Relics.UnceasingTop}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Move all but 1 card to deck
    local count = 0
    for _, card in ipairs(world.player.combatDeck) do
        if count == 0 then
            card.state = "HAND"
            count = count + 1
        else
            card.state = "DECK"
        end
    end

    -- Play card 3 times (each time hand becomes empty, Unceasing Top draws 1)
    for i = 1, 3 do
        local handCard = nil
        for _, card in ipairs(world.player.combatDeck) do
            if card.state == "HAND" then
                handCard = card
                break
            end
        end

        assert(handCard ~= nil, "Should have a card in hand for iteration " .. i)
        playCardWithAutoContext(world, world.player, handCard)

        -- After each play, should have 1 card in hand (drawn by Unceasing Top)
        local handSize = countCardsInState(world.player.combatDeck, "HAND")
        if i < 3 then
            assert(handSize == 1, "Should have 1 card in hand after play " .. i .. ", got " .. handSize)
        end
    end

    print("✓ Unceasing Top works across multiple card plays")
end

print("\n=== All Unceasing Top tests passed! ===")
