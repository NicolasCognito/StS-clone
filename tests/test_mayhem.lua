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
    local strike = Utils.copyCardTemplate(Cards.Strike)
    local defend = Utils.copyCardTemplate(Cards.Defend)

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = {strike, defend}
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
    local strike1 = Utils.copyCardTemplate(Cards.Strike)
    local strike2 = Utils.copyCardTemplate(Cards.Strike)
    local defend = Utils.copyCardTemplate(Cards.Defend)

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = {strike1, strike2, defend}
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
    local whirlwind = Utils.copyCardTemplate(Cards.Whirlwind)
    local strike = Utils.copyCardTemplate(Cards.Strike)

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = {whirlwind, strike}
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
    local pommelStrike = Utils.copyCardTemplate(Cards.PommelStrike)
    local strike = Utils.copyCardTemplate(Cards.Strike)
    local defend = Utils.copyCardTemplate(Cards.Defend)

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = {pommelStrike, strike, defend}
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
    -- First auto-cast: Pommel Strike (draws 1 card)
    -- Second auto-cast: Should get the NEW top card
    StartTurn.execute(world, world.player)

    -- Verify Pommel Strike was played
    assert(countLogEntries(world.log, "Pommel Strike") > 0 or countLogEntries(world.log, "dealt 9 damage") > 0,
        "Pommel Strike should be auto-played")

    -- Verify a second card was played
    local autocastCount = countLogEntries(world.log, "Auto%-casting")
    assert(autocastCount >= 2, "Should auto-cast 2 cards (found " .. autocastCount .. ")")

    print("✓ Mayhem correctly handles card that draws more cards")
end

print("\n=== All Mayhem tests passed! ===")
