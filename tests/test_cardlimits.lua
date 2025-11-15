-- Test card play limits (Velvet Choker and Normality)

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Relics = require("Data.relics")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local StartTurn = require("Pipelines.StartTurn")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")

math.randomseed(1337)  -- Deterministic randomness

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

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
            local context = ContextProvider.execute(world, player, request.contextProvider, request.card)
            if request.stability == "stable" then
                world.combat.stableContext = context
            else
                -- Use indexed tempContext
                local contextId = request.contextId
                world.combat.tempContext[contextId] = context
            end
            world.combat.contextRequest = nil
        end
    end
end

local function findCardInHand(deck)
    for _, card in ipairs(deck) do
        if card.state == "HAND" then
            return card
        end
    end
    return nil
end

print("=== Test 1: Velvet Choker - 6 card limit ===")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 10,  -- Plenty of energy
        cards = {}
    })

    -- Add 10 strikes to deck
    for i = 1, 10 do
        table.insert(world.player.masterDeck, copyCard(Cards.Strike))
    end

    -- Add Velvet Choker relic
    table.insert(world.player.relics, Relics.VelvetChoker)

    world.enemies = {copyEnemy(Enemies.Cultist)}
    world.enemies[1].hp = 100  -- High HP so it doesn't die
    world.enemies[1].maxHp = 100

    world.NoShuffle = true
    StartCombat.execute(world)

    print("Starting turn with Velvet Choker...")
    print("Expected: Can play 6 cards, 7th should be rejected")

    local cardsPlayed = 0
    for i = 1, 10 do  -- Try to play 10 cards
        local card = findCardInHand(world.player.combatDeck)
        if card then
            local success = playCardWithAutoContext(world, world.player, card)
            if success then
                cardsPlayed = cardsPlayed + 1
                print("  Card " .. cardsPlayed .. " played successfully")
            else
                print("  Card " .. (i) .. " REJECTED (expected at card 7+)")
                break
            end
        end
    end

    assert(cardsPlayed == 6, "Expected 6 cards played with Velvet Choker, got " .. cardsPlayed)
    assert(world.combat.cardsPlayedThisTurn == 6, "Counter should show 6 cards played")
    print("✓ Velvet Choker test passed: 6 cards played, 7th rejected")
end

print("\n=== Test 2: Normality - 3 card limit ===")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 10,
        cards = {}
    })

    -- Add 6 strikes + 1 Normality to deck
    for i = 1, 6 do
        table.insert(world.player.masterDeck, copyCard(Cards.Strike))
    end
    table.insert(world.player.masterDeck, copyCard(Cards.Normality))

    world.enemies = {copyEnemy(Enemies.Cultist)}
    world.enemies[1].hp = 100
    world.enemies[1].maxHp = 100

    world.NoShuffle = true
    StartCombat.execute(world)

    print("Starting turn with Normality in hand...")
    print("Expected: Can play 3 cards, 4th should be rejected")

    local cardsPlayed = 0
    for i = 1, 10 do
        local card = findCardInHand(world.player.combatDeck)
        if not card then
            break
        end

        -- Skip Normality (it's unplayable)
        if card.id == "Normality" then
            goto continue
        end

        local success = playCardWithAutoContext(world, world.player, card)
        if success then
            cardsPlayed = cardsPlayed + 1
            print("  Card " .. cardsPlayed .. " played successfully")
        else
            print("  Card " .. (i) .. " REJECTED (expected at card 4+)")
            break
        end

        ::continue::
    end

    assert(cardsPlayed == 3, "Expected 3 cards played with Normality, got " .. cardsPlayed)
    assert(world.combat.cardsPlayedThisTurn == 3, "Counter should show 3 cards played")
    print("✓ Normality test passed: 3 cards played, 4th rejected")
end

print("\n=== Test 3: Both Velvet Choker and Normality - most restrictive wins ===")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 10,
        cards = {}
    })

    for i = 1, 6 do
        table.insert(world.player.masterDeck, copyCard(Cards.Strike))
    end
    table.insert(world.player.masterDeck, copyCard(Cards.Normality))

    -- Add Velvet Choker
    table.insert(world.player.relics, Relics.VelvetChoker)

    world.enemies = {copyEnemy(Enemies.Cultist)}
    world.enemies[1].hp = 100
    world.enemies[1].maxHp = 100

    world.NoShuffle = true
    StartCombat.execute(world)

    print("Starting turn with BOTH Velvet Choker and Normality...")
    print("Expected: Normality's 3 card limit takes precedence (more restrictive)")

    local cardsPlayed = 0
    for i = 1, 10 do
        local card = findCardInHand(world.player.combatDeck)
        if not card then
            break
        end

        if card.id == "Normality" then
            goto continue
        end

        local success = playCardWithAutoContext(world, world.player, card)
        if success then
            cardsPlayed = cardsPlayed + 1
            print("  Card " .. cardsPlayed .. " played successfully")
        else
            print("  Card " .. (i) .. " REJECTED")
            break
        end

        ::continue::
    end

    assert(cardsPlayed == 3, "Expected 3 cards (Normality overrides Choker), got " .. cardsPlayed)
    print("✓ Combined test passed: Most restrictive limit (3) applied")
end

print("\n=== Test 4: Turn counter resets ===")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 10,
        cards = {}
    })

    for i = 1, 10 do
        table.insert(world.player.masterDeck, copyCard(Cards.Strike))
    end

    table.insert(world.player.relics, Relics.VelvetChoker)

    world.enemies = {copyEnemy(Enemies.Cultist)}
    world.enemies[1].hp = 100
    world.enemies[1].maxHp = 100

    world.NoShuffle = true
    StartCombat.execute(world)

    print("Playing 6 cards on turn 1...")
    for i = 1, 6 do
        local card = findCardInHand(world.player.combatDeck)
        if card then
            playCardWithAutoContext(world, world.player, card)
        end
    end

    assert(world.combat.cardsPlayedThisTurn == 6, "Turn 1: 6 cards played")
    print("  Turn 1: 6 cards played")

    -- Start new turn
    print("Starting turn 2...")
    StartTurn.execute(world, world.player)

    assert(world.combat.cardsPlayedThisTurn == 0, "Counter should reset to 0")
    print("  Counter reset to: " .. world.combat.cardsPlayedThisTurn)

    -- Play 6 more cards
    for i = 1, 6 do
        local card = findCardInHand(world.player.combatDeck)
        if card then
            playCardWithAutoContext(world, world.player, card)
        end
    end

    assert(world.combat.cardsPlayedThisTurn == 6, "Turn 2: Should play 6 cards again")
    print("  Turn 2: 6 cards played")
    print("✓ Counter reset test passed")
end

print("\n=== All tests passed! ===")
