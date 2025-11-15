-- Test: Necronomicurse Card
-- Tests the unique exhaust interaction: when exhausted, immediately returns to hand
-- (or discard pile if hand is full). Cannot be played even with Blue Candle.

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Relics = require("Data.relics")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")
local Exhaust = require("Pipelines.Exhaust")

math.randomseed(1337)

local function playCardWithAutoContext(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            return true
        elseif result == false then
            break
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

local function findCardByName(deck, name)
    for _, card in ipairs(deck) do
        if card.name == name then
            return card
        end
    end
    return nil
end

print("=== Necronomicurse Tests ===\n")

-- TEST 1: Necronomicurse is unplayable even with Blue Candle
print("Test 1: Necronomicurse is unplayable even with Blue Candle")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {Utils.copyCardTemplate(Cards.Necronomicurse)},
        relics = {Relics.BlueCandle}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local necronomicurse = world.player.combatDeck[1]
    assert(necronomicurse.state == "HAND", "Necronomicurse should be in hand")

    local result = playCardWithAutoContext(world, world.player, necronomicurse)

    -- Should fail to play even with Blue Candle
    assert(result ~= true, "Necronomicurse should not be playable even with Blue Candle")
    assert(necronomicurse.state == "HAND", "Necronomicurse should still be in hand")
    assert(world.player.hp == 80, "Player HP should be unchanged")

    print("✓ Necronomicurse is unplayable even with Blue Candle")
end

-- TEST 2: Necronomicurse returns to hand when exhausted
print("Test 2: Necronomicurse returns to hand when exhausted")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {Utils.copyCardTemplate(Cards.Necronomicurse)},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local necronomicurse = world.player.combatDeck[1]
    necronomicurse.state = "HAND"

    -- Manually exhaust the card
    Exhaust.execute(world, {card = necronomicurse, source = "Test"})

    -- Process the event queue (which includes the ON_CUSTOM_EFFECT from onExhaust)
    local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
    ProcessEventQueue.execute(world)

    -- Should be back in hand
    assert(necronomicurse.state == "HAND", "Necronomicurse should return to hand after exhaust")
    assert(countCardsInState(world.player.combatDeck, "EXHAUSTED_PILE") == 0, "No cards should be in exhausted pile")

    print("✓ Necronomicurse returns to hand when exhausted")
end

-- TEST 3: Necronomicurse goes to discard pile when hand is full
print("Test 3: Necronomicurse goes to discard pile when hand is full")
do
    -- Create 10 cards to fill hand (max hand size is 10)
    local cards = {}
    for i = 1, 9 do
        table.insert(cards, Utils.copyCardTemplate(Cards.Strike))
    end
    table.insert(cards, Utils.copyCardTemplate(Cards.Necronomicurse))

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = cards,
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- All 10 cards should be in hand (max hand size)
    assert(countCardsInState(world.player.combatDeck, "HAND") == 10, "Should have 10 cards in hand")

    local necronomicurse = findCardByName(world.player.combatDeck, "Necronomicurse")
    assert(necronomicurse ~= nil, "Should find Necronomicurse")

    -- Manually exhaust the card
    Exhaust.execute(world, {card = necronomicurse, source = "Test"})

    -- Process the event queue
    local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
    ProcessEventQueue.execute(world)

    -- Should go to discard pile (hand is full)
    assert(necronomicurse.state == "DISCARD_PILE", "Necronomicurse should go to discard pile when hand is full")
    assert(countCardsInState(world.player.combatDeck, "HAND") == 9, "Should have 9 cards in hand (Strike cards)")

    print("✓ Necronomicurse goes to discard pile when hand is full")
end

-- TEST 4: Strange Spoon can save Necronomicurse from exhaust
print("Test 4: Strange Spoon can save Necronomicurse from exhaust")
do
    -- Strange Spoon has 50% chance - with randomseed(1337) we can test this
    -- We'll run multiple times to see if it ever gets saved
    local savedAtLeastOnce = false
    local exhaustedAtLeastOnce = false

    for testRun = 1, 20 do
        math.randomseed(1337 + testRun)  -- Different seed each time

        local world = World.createWorld({
            id = "IronClad",
            maxHp = 80,
            currentHp = 80,
            maxEnergy = 6,
            cards = {Utils.copyCardTemplate(Cards.Necronomicurse)},
            relics = {Relics.StrangeSpoon}
        })

        world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
        world.NoShuffle = true
        StartCombat.execute(world)

        local necronomicurse = world.player.combatDeck[1]

        -- Manually exhaust the card
        Exhaust.execute(world, {card = necronomicurse, source = "Test"})

        -- Process the event queue
        local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
        ProcessEventQueue.execute(world)

        -- Check final state
        if necronomicurse.state == "DISCARD_PILE" then
            savedAtLeastOnce = true
        elseif necronomicurse.state == "HAND" then
            exhaustedAtLeastOnce = true
        end
    end

    assert(savedAtLeastOnce, "Strange Spoon should save Necronomicurse at least once in 20 runs")
    assert(exhaustedAtLeastOnce, "Necronomicurse should still exhaust (and return to hand) at least once in 20 runs")

    print("✓ Strange Spoon can save Necronomicurse from exhaust")
end

-- TEST 5: Multiple Necronomicurse cards each return independently
print("Test 5: Multiple Necronomicurse cards each return independently")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {
            Utils.copyCardTemplate(Cards.Necronomicurse),
            Utils.copyCardTemplate(Cards.Necronomicurse),
            Utils.copyCardTemplate(Cards.Necronomicurse)
        },
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Find all 3 Necronomicurse cards
    local curses = {}
    for _, card in ipairs(world.player.combatDeck) do
        if card.name == "Necronomicurse" then
            table.insert(curses, card)
        end
    end
    assert(#curses == 3, "Should have 3 Necronomicurse cards")

    -- Exhaust all 3
    for _, curse in ipairs(curses) do
        Exhaust.execute(world, {card = curse, source = "Test"})
    end

    -- Process the event queue
    local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
    ProcessEventQueue.execute(world)

    -- All 3 should return to hand
    assert(countCardsInState(world.player.combatDeck, "HAND") == 3, "All 3 Necronomicurse should return to hand")
    assert(countCardsInState(world.player.combatDeck, "EXHAUSTED_PILE") == 0, "No cards should remain in exhausted pile")

    print("✓ Multiple Necronomicurse cards each return independently")
end

-- TEST 6: Necronomicurse works with Corruption (Skills exhaust)
print("Test 6: Necronomicurse returns when exhausted by other effects")
do
    -- Simulate a card that exhausts after play
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {Utils.copyCardTemplate(Cards.Necronomicurse)},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local necronomicurse = world.player.combatDeck[1]

    -- Exhaust via different source
    Exhaust.execute(world, {card = necronomicurse, source = "Corruption"})

    -- Process the event queue
    local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
    ProcessEventQueue.execute(world)

    -- Should still return to hand
    assert(necronomicurse.state == "HAND", "Necronomicurse should return to hand regardless of exhaust source")

    print("✓ Necronomicurse returns when exhausted by other effects")
end

-- TEST 7: Verify log messages
print("Test 7: Verify log messages")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {Utils.copyCardTemplate(Cards.Necronomicurse)},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local necronomicurse = world.player.combatDeck[1]

    -- Clear log
    world.log = {}

    -- Exhaust the card
    Exhaust.execute(world, {card = necronomicurse, source = "Test"})

    -- Process the event queue
    local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
    ProcessEventQueue.execute(world)

    -- Check for log messages
    local hasExhaustLog = false
    local hasReturnLog = false

    for _, msg in ipairs(world.log) do
        if msg:match("exhausted") then
            hasExhaustLog = true
        end
        if msg:match("returns to your hand") then
            hasReturnLog = true
        end
    end

    assert(hasExhaustLog, "Should have exhaust log message")
    assert(hasReturnLog, "Should have return to hand log message")

    print("✓ Log messages are correct")
end

print("\n=== All Necronomicurse tests passed! ===")
