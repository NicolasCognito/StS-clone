local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local StartTurn = require("Pipelines.StartTurn")
local ContextProvider = require("Pipelines.ContextProvider")

math.randomseed(1337)

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

local function findLogIndex(log, text)
    for i, entry in ipairs(log) do
        if entry == text then
            return i
        end
    end
    return nil
end

local function labeledCard(template, label)
    local card = copyCard(template)
    card._testLabel = label
    return card
end

local function findCardByLabel(deck, label)
    for _, card in ipairs(deck) do
        if card._testLabel == label then
            return card
        end
    end
    error("Card with label " .. label .. " not found")
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

    -- Give enemy enough HP to survive 3 Strikes (6 damage each = 18 total)
    enemy.hp = 20
    enemy.maxHp = 20

    -- Set up Double Tap + Echo Form
    player.status = player.status or {}
    player.status.doubleTap = 1

    -- Set up Echo Form status effect (required for duplication system)
    player.status.echo_form = 1
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
    assert(enemy.hp == 2, "Enemy should have 2 HP left (20 - 18 from 3 Strikes)")

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

    -- Give enemy enough HP to survive 2 Heavy Blades (14 damage each = 28 total)
    enemy.hp = 30
    enemy.maxHp = 30

    StartTurn.execute(world, player)

    -- Play Heavy Blade (cost 2) - should trigger Necronomicon
    local heavyBladeCard = findCardById(player.combatDeck, "Heavy_Blade")
    playCardWithAutoContext(world, player, heavyBladeCard)

    assert(countLogEntries(world.log, "Necronomicon triggers!") == 1, "Necronomicon should trigger for Heavy Blade")
    assert(enemy.hp == 2, "Enemy should have 2 HP left (30 - 28 from 2 Heavy Blades)")
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

    -- Give enemy enough HP to survive 4 Strikes (6 damage each = 24 total)
    enemy.hp = 30
    enemy.maxHp = 30

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
    assert(enemy.hp == 6, "Enemy should have 6 HP left (30 - 24 from 4 Strikes)")

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
    player.status = player.status or {}
    player.status.echo_form = 2

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

-- TEST 6: Havoc consumes one Burst stack and queues auto-plays
print("TEST 6: Havoc Burst scheduling")
do
    local deck = {
        copyCard(Cards.Havoc),
        copyCard(Cards.Strike),
        copyCard(Cards.Strike),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend),
        copyCard(Cards.Defend),
        copyCard(Cards.Defend)
    }

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        cards = deck,
        relics = {}
    })

    world.enemies = { copyEnemy(Enemies.Goblin) }
    world.NoShuffle = true  -- Ensure deterministic card order (Havoc in hand, 2 Defends in deck)
    StartCombat.execute(world)

    local player = world.player
    player.status = player.status or {}
    player.status.burst = 2

    local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
    assert(#deckCards == 2, "Expected two cards remaining in draw pile after initial draw")
    local topCard = deckCards[1]
    local secondCard = deckCards[2]

    local havoc = findCardById(player.combatDeck, "Havoc")
    playCardWithAutoContext(world, player, havoc)

    assert(topCard.state == "EXHAUSTED_PILE", "Top draw pile card should have been played and exhausted by Havoc")
    assert(secondCard.state == "EXHAUSTED_PILE", "Second draw pile card should have been played by Havoc duplication and exhausted")
    assert(countLogEntries(world.log, "Burst triggers!") == 2, "Burst should trigger for Havoc and the first auto-played skill")
    assert((player.status.burst or 0) == 0, "Burst stacks should be fully consumed by Havoc chain")
end
print()

-- TEST 7: Context is re-collected for duplicated plays
print("TEST 7: Context resume for duplications")
do
    local deck = {
        copyCard(Cards.DaggerThrow),
        labeledCard(Cards.Defend, "DiscardA"),
        labeledCard(Cards.Strike, "DiscardB"),
        copyCard(Cards.Defend),
        copyCard(Cards.Strike),
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

    -- Enable NoShuffle for deterministic card order
    world.NoShuffle = true

    StartCombat.execute(world)

    local player = world.player
    local enemy = world.enemies[1]

    -- Give enemy enough HP to survive 2 Dagger Throws (9 damage each = 18 total)
    enemy.hp = 20
    enemy.maxHp = 20

    player.status = player.status or {}
    player.status.duplicationPotion = 1

    local daggerThrow = findCardById(player.combatDeck, "DaggerThrow")
    local discardA = findCardByLabel(player.combatDeck, "DiscardA")
    local discardB = findCardByLabel(player.combatDeck, "DiscardB")

    playCardWithAutoContext(world, player, daggerThrow)

    assert(countLogEntries(world.log, "Duplication Potion triggers!") == 1, "Duplication Potion should trigger exactly once")
    assert((player.status.duplicationPotion or 0) == 0, "Duplication Potion stack should be consumed")
    assert(discardA.state == "DISCARD_PILE", "First selected card should be discarded during initial play")
    assert(discardB.state == "DISCARD_PILE", "Second selected card should be discarded during duplicated play")
    assert(enemy.hp == 2, "Enemy should have 2 HP left (20 - 18 from 2 Dagger Throws)")

    print("  ✓ Context is correctly re-collected for duplicated plays")
end
print()

-- TEST 8: Forced replays resolve before other duplication sources
print("TEST 8: Forced replay priority")
do
    local deck = {
        copyCard(Cards.Strike),
        copyCard(Cards.Defend),
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

    -- Give enemy enough HP to survive 3 Strikes (6 damage each = 18 total)
    enemy.hp = 20
    enemy.maxHp = 20

    player.status = player.status or {}
    player.status.doubleTap = 1

    local strikeCard = findCardById(player.combatDeck, "Strike")
    PlayCard.queueForcedReplay(strikeCard, "Test Replay", 1)

    playCardWithAutoContext(world, player, strikeCard)

    local forcedIndex = findLogIndex(world.log, "Test Replay triggers!")
    local doubleIndex = findLogIndex(world.log, "Double Tap triggers!")
    assert(forcedIndex and doubleIndex and forcedIndex < doubleIndex, "Forced replay should resolve before Double Tap")
    assert(countLogEntries(world.log, "IronClad dealt 6 damage to Goblin") == 3, "Strike should hit three times (normal + forced + Double Tap)")
    assert((player.status.doubleTap or 0) == 0, "Double Tap stack should be consumed")
    assert(enemy.hp == 2, "Enemy should have 2 HP left (20 - 18 from 3 Strikes)")

    print("  ✓ Forced replays resolve before other duplication sources")
end
print()

print("=== ALL DUPLICATION STACKING TESTS PASSED ===")
