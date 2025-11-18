local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")

math.randomseed(1337)

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

local function findCard(deck, id)
    for _, card in ipairs(deck) do
        if card.id == id then
            return card
        end
    end
    error("Card " .. id .. " not found in deck")
end

local function createWorldWithDeck(deck)
    local world = World.createWorld({
        id = "Watcher",
        maxHp = 70,
        cards = deck,
        relics = {}
    })

    world.player.maxEnergy = 5
    world.player.energy = 5

    world.enemies = {
        copyEnemy(Enemies.Goblin)
    }

    -- Enable NoShuffle for deterministic test (Tantrum will still be added to deck)
    world.NoShuffle = true

    StartCombat.execute(world)
    return world
end

local function fulfillContext(world, player, override)
    local request = world.combat.contextRequest
    assert(request, "Context request should be populated")

    local context = override or ContextProvider.execute(world, player, request.contextProvider, request.card)
    assert(context, "ContextProvider failed to supply context for " .. (request.card and request.card.name or "unknown card"))

    if request.stability == "stable" then
        world.combat.stableContext = context
    else
        world.combat.tempContext = context
    end

    world.combat.contextRequest = nil
    return context
end

-- Test 1: Tantrum should deal damage 3 times, enter Wrath, and shuffle into draw pile
do
    local deck = {
        copyCard(Cards.Tantrum),
        copyCard(Cards.Defend),
        copyCard(Cards.Strike)
    }

    local world = createWorldWithDeck(deck)
    local player = world.player
    local tantrum = findCard(player.combatDeck, "Tantrum")
    local enemy = world.enemies[1]
    local initialHp = enemy.hp

    -- Verify Tantrum starts in hand
    assert(tantrum.state == "HAND", "Tantrum should start in hand")

    -- Play Tantrum (first call requests context)
    local result = PlayCard.execute(world, player, tantrum)
    assert(type(result) == "table" and result.needsContext, "Tantrum should request context")

    -- Fulfill context with the enemy
    fulfillContext(world, player, enemy)

    -- Play Tantrum (second call after context is provided)
    assert(PlayCard.execute(world, player, tantrum) == true, "Tantrum should resolve successfully")

    -- Verify damage was dealt 3 times
    local expectedDamage = tantrum.damage * tantrum.hits
    assert(enemy.hp == initialHp - expectedDamage, "Enemy should take " .. expectedDamage .. " damage (actual: " .. (initialHp - enemy.hp) .. ")")

    -- Verify Wrath stance was entered
    assert(player.currentStance == "Wrath", "Player should be in Wrath stance after playing Tantrum")

    -- Verify Tantrum was shuffled into draw pile (not discarded)
    assert(tantrum.state == "DECK", "Tantrum should be shuffled into draw pile")

    -- Verify log contains shuffle message
    local foundShuffleMessage = false
    for _, entry in ipairs(world.log) do
        if string.find(entry, "Tantrum") and string.find(entry, "shuffled into the draw pile") then
            foundShuffleMessage = true
            break
        end
    end
    assert(foundShuffleMessage, "Log should contain message about Tantrum being shuffled")

    print("Test 1 passed: Tantrum deals damage, enters Wrath, and shuffles into draw pile")
end

-- Test 2: Upgraded Tantrum should deal damage 4 times
do
    local deck = {
        copyCard(Cards.Tantrum),
        copyCard(Cards.Defend),
        copyCard(Cards.Strike)
    }

    deck[1]:onUpgrade()  -- Upgrade Tantrum to deal 4 hits

    local world = createWorldWithDeck(deck)
    local player = world.player
    local tantrum = findCard(player.combatDeck, "Tantrum")
    local enemy = world.enemies[1]
    local initialHp = enemy.hp

    assert(tantrum.hits == 4, "Upgraded Tantrum should have 4 hits")

    -- Play upgraded Tantrum (first call requests context)
    local result = PlayCard.execute(world, player, tantrum)
    assert(type(result) == "table" and result.needsContext, "Upgraded Tantrum should request context")

    -- Fulfill context with the enemy
    fulfillContext(world, player, enemy)

    -- Play upgraded Tantrum (second call after context is provided)
    assert(PlayCard.execute(world, player, tantrum) == true, "Upgraded Tantrum should resolve successfully")

    -- Verify damage was dealt 4 times
    local expectedDamage = tantrum.damage * tantrum.hits
    assert(enemy.hp == initialHp - expectedDamage, "Enemy should take " .. expectedDamage .. " damage")

    -- Verify Tantrum was still shuffled into draw pile
    print("Tantrum state after playing: " .. tostring(tantrum.state))
    print("Log entries:")
    for _, entry in ipairs(world.log) do
        if string.find(entry, "Tantrum") or string.find(entry, "shuffle") then
            print("  " .. entry)
        end
    end
    assert(tantrum.state == "DECK", "Upgraded Tantrum should be shuffled into draw pile (actual: " .. tostring(tantrum.state) .. ")")

    print("Test 2 passed: Upgraded Tantrum deals damage 4 times and shuffles into draw pile")
end

-- Test 3: Tantrum with self-exhaust flag should exhaust instead of shuffle
do
    local deck = {
        copyCard(Cards.Tantrum),
        copyCard(Cards.Defend),
        copyCard(Cards.Strike)
    }

    local world = createWorldWithDeck(deck)
    local player = world.player
    local tantrum = findCard(player.combatDeck, "Tantrum")

    -- Set the card to self-exhaust (overrides shuffleOnDiscard)
    tantrum.exhausts = true

    local enemy = world.enemies[1]

    -- Play Tantrum (first call requests context)
    local result = PlayCard.execute(world, player, tantrum)
    assert(type(result) == "table" and result.needsContext, "Tantrum should request context")

    -- Fulfill context with the enemy
    fulfillContext(world, player, enemy)

    -- Play Tantrum (second call after context is provided)
    assert(PlayCard.execute(world, player, tantrum) == true, "Tantrum should resolve successfully")

    -- Verify Tantrum was exhausted (not shuffled) due to self-exhaust
    assert(tantrum.state == "EXHAUSTED_PILE", "Tantrum should be exhausted when it has exhausts=true flag")

    -- Verify it was not shuffled
    local foundShuffleMessage = false
    for _, entry in ipairs(world.log) do
        if string.find(entry, "Tantrum") and string.find(entry, "shuffled into the draw pile") then
            foundShuffleMessage = true
            break
        end
    end
    assert(not foundShuffleMessage, "Log should NOT contain shuffle message when Tantrum self-exhausts")

    print("Test 3 passed: Tantrum with self-exhaust flag exhausts instead of shuffling")
end

-- Test 4: Tantrum played by Havoc should exhaust (not shuffle)
do
    local deck = {
        copyCard(Cards.Havoc),
        copyCard(Cards.Tantrum),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend)
    }

    local world = createWorldWithDeck(deck)
    local player = world.player

    local havoc = findCard(player.combatDeck, "Havoc")
    local tantrum = findCard(player.combatDeck, "Tantrum")

    -- Reset cards to controlled state
    for _, card in ipairs(player.combatDeck) do
        card.state = "EXHAUSTED_PILE"
    end

    -- Place Havoc in hand and Tantrum on top of deck
    havoc.state = "HAND"
    tantrum.state = "DECK"

    -- Verify setup
    local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
    assert(#deckCards == 1, "Expected only Tantrum in deck")
    assert(deckCards[1] == tantrum, "Tantrum should be on top of deck")

    -- Play Havoc (which will auto-play Tantrum and force it to exhaust)
    assert(PlayCard.execute(world, player, havoc) == true, "Havoc should resolve successfully")

    -- Verify Tantrum was exhausted by Havoc (not shuffled)
    assert(tantrum.state == "EXHAUSTED_PILE", "Tantrum should be exhausted when played by Havoc")
    assert(havoc.state == "EXHAUSTED_PILE", "Havoc should exhaust itself")

    -- Verify it was not shuffled
    local foundShuffleMessage = false
    for _, entry in ipairs(world.log) do
        if string.find(entry, "Tantrum") and string.find(entry, "shuffled into the draw pile") then
            foundShuffleMessage = true
            break
        end
    end
    assert(not foundShuffleMessage, "Log should NOT contain shuffle message when Tantrum is exhausted by Havoc")

    print("Test 4 passed: Tantrum exhausts when played by Havoc (forced exhaust)")
end

-- Test 5: Tantrum should shuffle back even when played multiple times in a turn
do
    local deck = {
        copyCard(Cards.Tantrum),
        copyCard(Cards.Tantrum),
        copyCard(Cards.Strike)
    }

    local world = createWorldWithDeck(deck)
    local player = world.player

    local tantrum1 = nil
    local tantrum2 = nil
    for _, card in ipairs(player.combatDeck) do
        if card.id == "Tantrum" then
            if not tantrum1 then
                tantrum1 = card
            else
                tantrum2 = card
            end
        end
    end

    assert(tantrum1 and tantrum2, "Should have two Tantrum cards")

    local enemy = world.enemies[1]

    -- Play first Tantrum (request context)
    local result1 = PlayCard.execute(world, player, tantrum1)
    assert(type(result1) == "table" and result1.needsContext, "First Tantrum should request context")
    fulfillContext(world, player, enemy)
    assert(PlayCard.execute(world, player, tantrum1) == true, "First Tantrum should resolve successfully")
    assert(tantrum1.state == "DECK", "First Tantrum should be shuffled into draw pile")

    -- Play second Tantrum (request context)
    local result2 = PlayCard.execute(world, player, tantrum2)
    assert(type(result2) == "table" and result2.needsContext, "Second Tantrum should request context")
    fulfillContext(world, player, enemy)
    assert(PlayCard.execute(world, player, tantrum2) == true, "Second Tantrum should resolve successfully")
    assert(tantrum2.state == "DECK", "Second Tantrum should be shuffled into draw pile")

    -- Count shuffle messages in log
    local shuffleCount = 0
    for _, entry in ipairs(world.log) do
        if string.find(entry, "Tantrum") and string.find(entry, "shuffled into the draw pile") then
            shuffleCount = shuffleCount + 1
        end
    end
    assert(shuffleCount == 2, "Log should contain two shuffle messages for two Tantrum cards")

    print("Test 5 passed: Multiple Tantrum cards shuffle back independently")
end

print("All Tantrum tests passed!")
