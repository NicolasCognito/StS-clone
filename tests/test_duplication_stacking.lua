local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local StartTurn = require("Pipelines.StartTurn")
local ApplyPower = require("Pipelines.ApplyPower")
local ContextProvider = require("Pipelines.ContextProvider")

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

local function countLogEntries(log, text)
    local total = 0
    for _, entry in ipairs(log) do
        if entry == text then
            total = total + 1
        end
    end
    return total
end

local function playCardWithAutoContext(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            return true
        end

        assert(type(result) == "table" and result.needsContext, "Expected context request while resolving " .. card.name)
        local request = world.combat.contextRequest
        assert(request, "Context request should exist")

        local context = ContextProvider.execute(world, player, request.contextProvider, request.card)
        assert(context, "Failed to collect context for " .. card.name)

        if request.stability == "stable" then
            world.combat.stableContext = context
        else
            world.combat.tempContext = context
        end

        world.combat.contextRequest = nil
    end
end

print("=== DUPLICATION STACKING TESTS ===")
print()

-- TEST 1: Double Tap + Echo Form (both should trigger)
print("TEST 1: Double Tap + Echo Form")
do
    local deck = {
        copyCard(Cards.Strike),
        copyCard(Cards.Defend)
    }

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        cards = deck,
        relics = {}
    })

    world.enemies = { copyEnemy(Enemies.Goblin) }
    StartCombat.execute(world)

    local player = world.player
    local enemy = world.enemies[1]

    -- Set up Double Tap + Echo Form
    player.status = player.status or {}
    player.status.doubleTap = 1
    player.status.echoFormThisTurn = 1

    local strikeCard = findCardById(player.combatDeck, "Strike")
    playCardWithAutoContext(world, player, strikeCard)

    -- Strike should be played 3 times:
    -- 1. Normal play
    -- 2. Double Tap trigger (priority 2)
    -- 3. Echo Form trigger (priority 3)
    assert(countLogEntries(world.log, "Double Tap triggers!") == 1, "Double Tap should trigger once")
    assert(countLogEntries(world.log, "Echo Form triggers!") == 1, "Echo Form should trigger once")
    assert(countLogEntries(world.log, "IronClad dealt 6 damage to Goblin") == 3, "Strike should deal damage 3 times")
    assert((player.status.doubleTap or 0) == 0, "Double Tap should be consumed")
    assert((player.status.echoFormThisTurn or 0) == 0, "Echo Form should be consumed")

    print("  ✓ Double Tap + Echo Form stacking works correctly (3 total plays)")
end
print()

-- TEST 2: Necronomicon (cost 2+ Attack, once per turn)
print("TEST 2: Necronomicon")
do
    local deck = {
        copyCard(Cards.HeavyBlade),     -- Attack cost 2
        copyCard(Cards.Strike),   -- Attack cost 1
        copyCard(Cards.Defend)
    }

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        cards = deck,
        relics = {
            {id = "Necronomicon", name = "Necronomicon"}
        }
    })

    world.enemies = { copyEnemy(Enemies.Goblin) }
    StartCombat.execute(world)

    local player = world.player
    local enemy = world.enemies[1]

    StartTurn.execute(world, player)

    -- Play Heavy Blade (cost 2) - should trigger Necronomicon
    local heavyBladeCard = findCardById(player.combatDeck, "Heavy_Blade")
    playCardWithAutoContext(world, player, heavyBladeCard)

    assert(countLogEntries(world.log, "Necronomicon triggers!") == 1, "Necronomicon should trigger for Heavy Blade")
    assert(player.status.necronomiconThisTurn == true, "Necronomicon flag should be set")

    -- Play Strike (cost 1) - should NOT trigger Necronomicon (cost < 2)
    local strikeCard = findCardById(player.combatDeck, "Strike")
    playCardWithAutoContext(world, player, strikeCard)

    assert(countLogEntries(world.log, "Necronomicon triggers!") == 1, "Necronomicon should NOT trigger for Strike")

    print("  ✓ Necronomicon triggers for cost 2+ Attacks")
    print("  ✓ Necronomicon only triggers once per turn")
end
print()

-- TEST 3: Burst (Skills only)
print("TEST 3: Burst")
do
    local deck = {
        copyCard(Cards.Defend),   -- Skill
        copyCard(Cards.Strike)    -- Attack
    }

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        cards = deck,
        relics = {}
    })

    world.enemies = { copyEnemy(Enemies.Goblin) }
    StartCombat.execute(world)

    local player = world.player
    local enemy = world.enemies[1]

    -- Set up Burst
    player.status = player.status or {}
    player.status.burst = 1

    -- Play Defend (Skill) - should trigger Burst
    local defendCard = findCardById(player.combatDeck, "Defend")
    playCardWithAutoContext(world, player, defendCard)

    assert(countLogEntries(world.log, "Burst triggers!") == 1, "Burst should trigger for Skill")
    assert((player.status.burst or 0) == 0, "Burst should be consumed")
    assert(player.block == 10, "Defend should grant 5 block twice (10 total)")

    -- Set up Burst again
    player.status.burst = 1

    -- Play Strike (Attack) - should NOT trigger Burst
    local strikeCard = findCardById(player.combatDeck, "Strike")
    playCardWithAutoContext(world, player, strikeCard)

    assert(countLogEntries(world.log, "Burst triggers!") == 1, "Burst should NOT trigger for Attack")
    assert(player.status.burst == 1, "Burst should not be consumed by Attack")

    print("  ✓ Burst triggers for Skills only")
end
print()

-- TEST 4: Priority order (Duplication Potion > Double Tap > Echo Form)
print("TEST 4: Priority order")
do
    local deck = {
        copyCard(Cards.Strike),
        copyCard(Cards.Defend)
    }

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        cards = deck,
        relics = {}
    })

    world.enemies = { copyEnemy(Enemies.Goblin) }
    StartCombat.execute(world)

    local player = world.player
    local enemy = world.enemies[1]

    -- Set up all three sources
    player.status = player.status or {}
    player.status.duplicationPotion = 1  -- Priority 1
    player.status.doubleTap = 1          -- Priority 2
    player.status.echoFormThisTurn = 1   -- Priority 3

    local strikeCard = findCardById(player.combatDeck, "Strike")
    playCardWithAutoContext(world, player, strikeCard)

    -- Strike should be played 4 times:
    -- 1. Normal play
    -- 2. Duplication Potion (consumed first by priority)
    -- 3. Double Tap (consumed second)
    -- 4. Echo Form (consumed third)
    assert(countLogEntries(world.log, "Duplication Potion triggers!") == 1, "Duplication Potion should trigger")
    assert(countLogEntries(world.log, "Double Tap triggers!") == 1, "Double Tap should trigger")
    assert(countLogEntries(world.log, "Echo Form triggers!") == 1, "Echo Form should trigger")
    assert(countLogEntries(world.log, "IronClad dealt 6 damage to Goblin") == 4, "Strike should deal damage 4 times")
    assert((player.status.duplicationPotion or 0) == 0, "Duplication Potion consumed")
    assert((player.status.doubleTap or 0) == 0, "Double Tap consumed")
    assert((player.status.echoFormThisTurn or 0) == 0, "Echo Form consumed")

    print("  ✓ Priority order: Duplication Potion > Double Tap > Echo Form")
end
print()

-- TEST 5: Echo Form with multiple stacks
print("TEST 5: Echo Form with multiple stacks")
do
    local deck = {
        copyCard(Cards.Strike),
        copyCard(Cards.Defend),
        copyCard(Cards.Bash)
    }

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        cards = deck,
        relics = {}
    })

    world.enemies = { copyEnemy(Enemies.Goblin) }
    StartCombat.execute(world)

    local player = world.player
    local enemy = world.enemies[1]

    -- Simulate Echo Form with 2 stacks
    player.powers = player.powers or {}
    table.insert(player.powers, {id = "EchoForm", stacks = 2})

    -- Start turn (this sets echoFormThisTurn = 2)
    StartTurn.execute(world, player)

    assert(player.status.echoFormThisTurn == 2, "Echo Form should set counter to 2")

    -- Play first card (Strike) - should trigger
    local strikeCard = findCardById(player.combatDeck, "Strike")
    playCardWithAutoContext(world, player, strikeCard)

    assert(countLogEntries(world.log, "Echo Form triggers!") == 1, "Echo Form should trigger for first card")
    assert(player.status.echoFormThisTurn == 1, "Echo Form counter should decrement to 1")

    -- Play second card (Defend) - should trigger
    local defendCard = findCardById(player.combatDeck, "Defend")
    playCardWithAutoContext(world, player, defendCard)

    assert(countLogEntries(world.log, "Echo Form triggers!") == 2, "Echo Form should trigger for second card")
    assert((player.status.echoFormThisTurn or 0) == 0, "Echo Form counter should decrement to 0")

    -- Play third card (Bash) - should NOT trigger
    local bashCard = findCardById(player.combatDeck, "Bash")
    playCardWithAutoContext(world, player, bashCard)

    assert(countLogEntries(world.log, "Echo Form triggers!") == 2, "Echo Form should NOT trigger for third card")

    print("  ✓ Echo Form with multiple stacks works correctly")
end
print()

print("=== ALL DUPLICATION STACKING TESTS PASSED ===")
