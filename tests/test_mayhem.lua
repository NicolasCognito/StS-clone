-- TEST: Mayhem Power and Auto-casting
-- Verifies that Mayhem correctly plays top cards from deck at start of turn

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local StartTurn = require("Pipelines.StartTurn")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")

math.randomseed(1337)

local function playCardWithAutoContext(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            return true
        end
        if result == false then
            break
        end

        if type(result) == "table" and result.needsContext then
            local request = world.combat.contextRequest
            local context = ContextProvider.execute(world, player, request.contextProvider, request.card)
            if request.stability == "stable" then
                world.combat.stableContext = context
            else
                world.combat.tempContext = context
            end
            world.combat.contextRequest = nil
        end
    end
end

local function countLogEntries(log, pattern)
    local count = 0
    for _, entry in ipairs(log) do
        if string.find(entry, pattern) then
            count = count + 1
        end
    end
    return count
end

print("=== Test 1: Mayhem (1 stack) plays top card at start of turn ===")
do
    -- Need enough cards: 5 drawn at combat start + 5 drawn at turn start + 1 for Mayhem
    local cards = {}
    for i = 1, 12 do
        table.insert(cards, Utils.copyCardTemplate(Cards.Strike))
    end

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = cards
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Set enemy HP high enough to survive
    world.enemies[1].hp = 20
    world.enemies[1].maxHp = 20

    -- Apply Mayhem status
    world.player.status.mayhem = 1

    -- Clear log
    world.log = {}

    -- Start turn (should trigger Mayhem)
    StartTurn.execute(world, world.player)

    -- Verify Mayhem triggered
    assert(countLogEntries(world.log, "Mayhem") > 0, "Mayhem should trigger")
    assert(countLogEntries(world.log, "Auto%-casting") > 0, "Auto-casting should occur")

    -- Verify Strike was played (top card)
    assert(countLogEntries(world.log, "Strike") > 0, "Strike should be auto-played")
    assert(countLogEntries(world.log, "dealt 6 damage") > 0, "Strike should deal damage")

    -- Verify enemy took damage
    assert(world.enemies[1].hp == 14, "Enemy should take 6 damage (20 - 6 = 14)")

    print("✓ Mayhem (1 stack) correctly plays top card")
end

print("\n=== Test 2: Mayhem (2 stacks) plays top 2 cards in sequence ===")
do
    -- Need enough cards: 5 drawn at combat start + 5 drawn at turn start + 2 for Mayhem
    local cards = {}
    for i = 1, 13 do
        table.insert(cards, Utils.copyCardTemplate(Cards.Strike))
    end

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = cards
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Set enemy HP high enough to survive 2 Strikes (12 damage)
    world.enemies[1].hp = 20
    world.enemies[1].maxHp = 20

    -- Apply Mayhem with 2 stacks
    world.player.status.mayhem = 2

    -- Clear log
    world.log = {}

    -- Start turn (should trigger Mayhem twice)
    StartTurn.execute(world, world.player)

    -- Verify Mayhem triggered
    assert(countLogEntries(world.log, "Mayhem") > 0, "Mayhem should trigger")

    -- Verify both Strikes were played
    local strikeCount = countLogEntries(world.log, "dealt 6 damage")
    assert(strikeCount == 2, "Should play 2 Strikes (found " .. strikeCount .. ")")

    -- Verify enemy took damage from both
    assert(world.enemies[1].hp == 8, "Enemy should take 12 damage (20 - 12 = 8)")

    print("✓ Mayhem (2 stacks) correctly plays top 2 cards in sequence")
end

print("\n=== Test 3: Mayhem with X-cost card uses current energy ===")
do
    -- Need enough cards: 5 at start + 5 at turn + then whirlwind on top
    local cards = {}
    for i = 1, 10 do
        table.insert(cards, Utils.copyCardTemplate(Cards.Strike))
    end
    table.insert(cards, Utils.copyCardTemplate(Cards.Whirlwind))
    table.insert(cards, Utils.copyCardTemplate(Cards.Strike))

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = cards
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Set enemy HP high enough
    world.enemies[1].hp = 50
    world.enemies[1].maxHp = 50

    -- Apply Mayhem
    world.player.status.mayhem = 1

    -- Player starts with 3 energy
    local initialEnergy = world.player.energy

    -- Clear log
    world.log = {}

    -- Start turn (should auto-play Whirlwind with X=3)
    StartTurn.execute(world, world.player)

    -- Verify Whirlwind was played
    assert(countLogEntries(world.log, "Whirlwind") > 0, "Whirlwind should be auto-played")

    -- Energy should NOT be spent (Mayhem plays for free)
    assert(world.player.energy == initialEnergy, "Energy should not be spent (Mayhem plays for free)")

    -- But Whirlwind should hit X times where X = current energy
    -- Whirlwind deals 5 damage per hit (base)
    local expectedDamage = 5 * initialEnergy
    assert(world.enemies[1].hp == 50 - expectedDamage, "Whirlwind should hit " .. initialEnergy .. " times")

    print("✓ Mayhem with X-cost card uses current energy without spending it")
end

print("\n=== Test 4: Mayhem with empty deck ===")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = {}  -- No cards
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Apply Mayhem
    world.player.status.mayhem = 1

    -- Clear log
    world.log = {}

    -- Start turn (should handle empty deck gracefully)
    StartTurn.execute(world, world.player)

    -- Verify no crash, message logged
    assert(countLogEntries(world.log, "No more cards in draw pile") > 0, "Should log 'no more cards'")

    print("✓ Mayhem with empty deck handled gracefully")
end

print("\n=== Test 5: Mayhem plays card that draws more cards ===")
do
    -- Need enough cards for combat start (5) + turn start (5) + Mayhem (2) + drawn card
    local cards = {}
    for i = 1, 10 do
        table.insert(cards, Utils.copyCardTemplate(Cards.Strike))
    end
    -- Dagger Throw will be on top of deck after initial draws
    table.insert(cards, Utils.copyCardTemplate(Cards.DaggerThrow))
    table.insert(cards, Utils.copyCardTemplate(Cards.Strike))
    table.insert(cards, Utils.copyCardTemplate(Cards.Strike))

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = cards
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Set enemy HP
    world.enemies[1].hp = 50
    world.enemies[1].maxHp = 50

    -- Apply Mayhem with 2 stacks
    world.player.status.mayhem = 2

    -- Clear log
    world.log = {}

    -- Start turn
    -- First auto-cast: Dagger Throw (draws 1 card)
    -- Second auto-cast: Should get the NEW top card
    StartTurn.execute(world, world.player)

    -- Verify Dagger Throw was played
    assert(countLogEntries(world.log, "Dagger Throw") > 0 or countLogEntries(world.log, "dealt 9 damage") > 0,
        "Dagger Throw should be auto-played")

    -- Verify a second card was played
    local autocastCount = countLogEntries(world.log, "Auto%-casting")
    assert(autocastCount >= 2, "Should auto-cast 2 cards (found " .. autocastCount .. ")")

    print("✓ Mayhem correctly handles card that draws more cards")
end

print("\n=== Test 6: Mayhem with unplayable card (no onPlay) ===")
do
    -- Need enough cards for combat start (5) + turn start (5) + Mayhem (2)
    local cards = {}
    for i = 1, 10 do
        table.insert(cards, Utils.copyCardTemplate(Cards.Strike))
    end

    -- Create an unplayable card (no onPlay function) - will be on top after draws
    local unplayableCard = {
        id = "Unplayable_Test",
        name = "Unplayable Test Card",
        cost = 0,
        type = "STATUS",
        -- No onPlay function!
        state = "DECK"
    }
    table.insert(cards, unplayableCard)
    table.insert(cards, Utils.copyCardTemplate(Cards.Strike))

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = cards
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Set enemy HP
    world.enemies[1].hp = 20
    world.enemies[1].maxHp = 20

    -- Apply Mayhem with 2 stacks
    world.player.status.mayhem = 2

    -- Clear log
    world.log = {}

    -- Start turn
    -- First auto-cast: Unplayable card (should skip)
    -- Second auto-cast: Strike (should execute normally)
    StartTurn.execute(world, world.player)

    -- Verify unplayable card was handled
    assert(countLogEntries(world.log, "Unplayable") > 0, "Should log 'Unplayable' for card with no onPlay")
    assert(countLogEntries(world.log, "has no effect") > 0, "Should log 'has no effect'")

    -- Verify Strike was still played (second autocast)
    assert(countLogEntries(world.log, "dealt 6 damage") > 0, "Strike should still be auto-played after unplayable card")

    -- Verify enemy took damage from Strike only
    assert(world.enemies[1].hp == 14, "Enemy should take 6 damage from Strike (20 - 6 = 14)")

    -- Verify unplayable card is in discard pile
    local discardCount = 0
    for _, card in ipairs(world.player.combatDeck) do
        if card.id == "Unplayable_Test" and card.state == "DISCARD_PILE" then
            discardCount = discardCount + 1
        end
    end
    assert(discardCount == 1, "Unplayable card should be in discard pile")

    print("✓ Mayhem correctly handles unplayable cards (no onPlay)")
end

print("\n=== Test 7: Nested autocasting - Mayhem → Havoc → Havoc → Strike ===")
do
    -- Need enough cards: 5 at combat start + 5 at turn start + cards for autocasting
    local cards = {}
    for i = 1, 10 do
        table.insert(cards, Utils.copyCardTemplate(Cards.Defend))
    end

    -- Set up the chain: Havoc1 (top after draws) -> Havoc2 -> Strike
    table.insert(cards, Utils.copyCardTemplate(Cards.Havoc))  -- This will be played by Mayhem
    table.insert(cards, Utils.copyCardTemplate(Cards.Havoc))  -- This will be played by first Havoc
    table.insert(cards, Utils.copyCardTemplate(Cards.Strike)) -- This will be played by second Havoc

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = cards
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Set enemy HP
    world.enemies[1].hp = 50
    world.enemies[1].maxHp = 50

    -- Apply Mayhem (1 stack)
    world.player.status.mayhem = 1

    -- Clear log
    world.log = {}

    -- Start turn
    -- Mayhem should autocast first Havoc
    -- First Havoc should play second Havoc (from top of deck)
    -- Second Havoc should play Strike (from top of deck)
    StartTurn.execute(world, world.player)

    -- Verify the chain
    assert(countLogEntries(world.log, "Mayhem") > 0, "Mayhem should trigger")

    -- Should see "Auto-casting: Havoc" from Mayhem
    assert(countLogEntries(world.log, "Auto%-casting: Havoc") > 0, "Mayhem should autocast Havoc")

    -- Should see Havoc played twice (once by Mayhem, once by first Havoc)
    local havocPlayCount = countLogEntries(world.log, "played Havoc")
    assert(havocPlayCount >= 2, "Should play Havoc twice (found " .. havocPlayCount .. ")")

    -- Should see Strike played by second Havoc
    assert(countLogEntries(world.log, "played Strike") > 0, "Second Havoc should play Strike")

    -- Verify Strike dealt damage
    assert(countLogEntries(world.log, "dealt 6 damage") > 0, "Strike should deal damage")
    assert(world.enemies[1].hp == 44, "Enemy should take 6 damage (50 - 6 = 44)")

    print("✓ Nested autocasting works correctly (Mayhem → Havoc → Havoc → Strike)")
end

print("\n=== All Mayhem tests passed! ===")
