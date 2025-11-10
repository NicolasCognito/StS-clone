local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")

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

local function countCardsInState(deck, state)
    local count = 0
    for _, card in ipairs(deck) do
        if card.state == state then
            count = count + 1
        end
    end
    return count
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

print("=== OMNISCIENCE TESTS ===")
print()

-- TEST 1: Basic Omniscience functionality
print("TEST 1: Basic Omniscience - Choose and play Strike twice")
do
    local deck = {
        copyCard(Cards.Omniscience),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend),
        copyCard(Cards.Bash)
    }

    local world = World.createWorld({
        id = "Watcher",
        maxHp = 80,
        cards = deck,
        relics = {}
    })

    world.enemies = { copyEnemy(Enemies.Goblin) }
    StartCombat.execute(world)

    local player = world.player
    local enemy = world.enemies[1]

    -- Set up: Omniscience in hand, Strike in draw pile
    local omniscienceCard = findCardById(player.combatDeck, "Omniscience")
    local strikeCard = findCardById(player.combatDeck, "Strike")

    assert(omniscienceCard.state == "HAND", "Omniscience should be in hand")
    assert(strikeCard.state == "DECK", "Strike should be in draw pile")

    -- Play Omniscience, choosing Strike
    PlayCard.execute(world, player, omniscienceCard, {strikeCard})

    -- Strike should be played twice (6 damage each time = 12 total)
    assert(countLogEntries(world.log, "Watcher dealt 6 damage to Goblin") == 2, "Strike should deal damage twice")
    assert(enemy.hp == 38, "Enemy should take 12 damage total (50 - 12 = 38)")

    -- Strike should be exhausted
    assert(strikeCard.state == "EXHAUSTED_PILE", "Strike should be exhausted")
    assert(countCardsInState(player.combatDeck, "EXHAUSTED_PILE") == 1, "Only Strike should be exhausted")

    print("  ✓ Omniscience plays chosen card twice and exhausts it")
end
print()

-- TEST 2: Omniscience does NOT interact with duplication system
print("TEST 2: Omniscience with Double Tap active")
do
    local deck = {
        copyCard(Cards.Omniscience),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend)
    }

    local world = World.createWorld({
        id = "Watcher",
        maxHp = 80,
        cards = deck,
        relics = {}
    })

    world.enemies = { copyEnemy(Enemies.Goblin) }
    StartCombat.execute(world)

    local player = world.player
    local enemy = world.enemies[1]

    -- Set up Double Tap status
    player.status = player.status or {}
    player.status.doubleTap = 1

    local omniscienceCard = findCardById(player.combatDeck, "Omniscience")
    local strikeCard = findCardById(player.combatDeck, "Strike")

    -- Play Omniscience, choosing Strike (Attack)
    PlayCard.execute(world, player, omniscienceCard, {strikeCard})

    -- Strike should ONLY play twice (via Omniscience), NOT 3 or 4 times
    -- Double Tap should NOT trigger because Strike is played via Omniscience, not normally
    assert(countLogEntries(world.log, "Watcher dealt 6 damage to Goblin") == 2, "Strike should only deal damage twice")
    assert(enemy.hp == 38, "Enemy should take 12 damage (not more)")
    assert(player.status.doubleTap == 1, "Double Tap should NOT be consumed")

    print("  ✓ Omniscience does NOT interact with duplication system")
end
print()

-- TEST 3: Omniscience with X-cost card (Whirlwind)
print("TEST 3: Omniscience with Whirlwind (X-cost)")
do
    local deck = {
        copyCard(Cards.Omniscience),
        copyCard(Cards.Whirlwind),
        copyCard(Cards.Defend)
    }

    local world = World.createWorld({
        id = "Watcher",
        maxHp = 80,
        cards = deck,
        relics = {}
    })

    world.enemies = { copyEnemy(Enemies.Goblin) }
    StartCombat.execute(world)

    local player = world.player
    local enemy = world.enemies[1]

    local omniscienceCard = findCardById(player.combatDeck, "Omniscience")
    local whirlwindCard = findCardById(player.combatDeck, "Whirlwind")

    -- Play Omniscience, choosing Whirlwind
    PlayCard.execute(world, player, omniscienceCard, {whirlwindCard})

    -- Whirlwind is played for 0 energy (via Omniscience), so it hits 0 times each play
    -- It should be called twice, but deal 0 damage each time
    assert(whirlwindCard.state == "EXHAUSTED_PILE", "Whirlwind should be exhausted")
    -- Enemy should take 0 damage (Whirlwind with X=0 hits 0 times)
    assert(enemy.hp == 50, "Enemy should take no damage (X=0)")

    print("  ✓ Omniscience with X-cost card works (X=0)")
end
print()

-- TEST 4: Omniscience with card requiring target context
print("TEST 4: Omniscience with Bash (requires enemy target)")
do
    local deck = {
        copyCard(Cards.Omniscience),
        copyCard(Cards.Bash),
        copyCard(Cards.Defend)
    }

    local world = World.createWorld({
        id = "Watcher",
        maxHp = 80,
        cards = deck,
        relics = {}
    })

    world.enemies = { copyEnemy(Enemies.Goblin) }
    StartCombat.execute(world)

    local player = world.player
    local enemy = world.enemies[1]

    local omniscienceCard = findCardById(player.combatDeck, "Omniscience")
    local bashCard = findCardById(player.combatDeck, "Bash")

    -- Play Omniscience, choosing Bash
    PlayCard.execute(world, player, omniscienceCard, {bashCard})

    -- Bash should deal 8 damage twice and apply Vulnerable 2 stacks twice (4 total)
    assert(countLogEntries(world.log, "Watcher dealt 8 damage to Goblin") == 2, "Bash should deal damage twice")
    assert(enemy.hp == 34, "Enemy should take 16 damage (50 - 16 = 34)")
    assert(enemy.status.vulnerable == 4, "Enemy should have 4 Vulnerable (2 + 2)")
    assert(bashCard.state == "EXHAUSTED_PILE", "Bash should be exhausted")

    print("  ✓ Omniscience with targeted card works correctly")
end
print()

print("=== ALL OMNISCIENCE TESTS PASSED ===")
