-- TEST: Distilled Chaos Potion
-- Verifies that Distilled Chaos correctly plays top 3 cards from deck

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local Potions = require("Data.potions")
local StartCombat = require("Pipelines.StartCombat")
local UsePotion = require("Pipelines.UsePotion")

math.randomseed(1337)

local function countLogEntries(log, pattern)
    local count = 0
    for _, entry in ipairs(log) do
        if string.find(entry, pattern) then
            count = count + 1
        end
    end
    return count
end

print("=== Test 1: Distilled Chaos plays top 3 cards ===")
do
    local strike1 = Utils.copyCardTemplate(Cards.Strike)
    local strike2 = Utils.copyCardTemplate(Cards.Strike)
    local strike3 = Utils.copyCardTemplate(Cards.Strike)
    local defend = Utils.copyCardTemplate(Cards.Defend)

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = {strike1, strike2, strike3, defend},
        masterPotions = {Potions.DistilledChaos}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Set enemy HP high enough to survive 3 Strikes (18 damage)
    world.enemies[1].hp = 25
    world.enemies[1].maxHp = 25

    -- Clear log
    world.log = {}

    -- Use Distilled Chaos potion
    UsePotion.execute(world, world.player, 1)

    -- Verify potion effect triggered
    assert(countLogEntries(world.log, "Distilled Chaos") > 0, "Distilled Chaos should trigger")

    -- Verify 3 Strikes were played
    local strikeCount = countLogEntries(world.log, "dealt 6 damage")
    assert(strikeCount == 3, "Should play 3 Strikes (found " .. strikeCount .. ")")

    -- Verify enemy took damage from all 3
    assert(world.enemies[1].hp == 7, "Enemy should take 18 damage (25 - 18 = 7)")

    -- Verify potion was consumed
    assert(#world.player.masterPotions == 0, "Potion should be consumed")

    print("✓ Distilled Chaos correctly plays top 3 cards")
end

print("\n=== Test 2: Distilled Chaos with fewer than 3 cards ===")
do
    local strike1 = Utils.copyCardTemplate(Cards.Strike)
    local strike2 = Utils.copyCardTemplate(Cards.Strike)

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = {strike1, strike2},
        masterPotions = {Potions.DistilledChaos}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Set enemy HP
    world.enemies[1].hp = 20
    world.enemies[1].maxHp = 20

    -- Clear log
    world.log = {}

    -- Use Distilled Chaos (should play only 2 cards, not crash)
    UsePotion.execute(world, world.player, 1)

    -- Verify it played what it could
    local strikeCount = countLogEntries(world.log, "dealt 6 damage")
    assert(strikeCount == 2, "Should play 2 Strikes (all available)")

    -- Verify "no more cards" message
    assert(countLogEntries(world.log, "No more cards in draw pile") > 0, "Should log 'no more cards'")

    print("✓ Distilled Chaos handles fewer than 3 cards gracefully")
end

print("\n=== Test 3: Distilled Chaos with Sacred Bark (plays 6 cards) ===")
do
    -- Create 6 Strikes
    local strikes = {}
    for i = 1, 6 do
        table.insert(strikes, Utils.copyCardTemplate(Cards.Strike))
    end
    local defend = Utils.copyCardTemplate(Cards.Defend)
    table.insert(strikes, defend)

    -- Create Sacred Bark relic
    local Relics = require("Data.relics")
    local sacredBark = {
        id = "Sacred_Bark",
        name = "Sacred Bark",
        description = "Potions have double effectiveness"
    }

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = strikes,
        masterPotions = {Potions.DistilledChaos},
        relics = {sacredBark}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Set enemy HP high enough to survive 6 Strikes (36 damage)
    world.enemies[1].hp = 50
    world.enemies[1].maxHp = 50

    -- Clear log
    world.log = {}

    -- Use Distilled Chaos (should play 6 cards with Sacred Bark)
    UsePotion.execute(world, world.player, 1)

    -- Verify Sacred Bark triggered
    assert(countLogEntries(world.log, "Sacred Bark") > 0, "Sacred Bark should trigger")

    -- Verify 6 Strikes were played
    local strikeCount = countLogEntries(world.log, "dealt 6 damage")
    assert(strikeCount == 6, "Should play 6 Strikes with Sacred Bark (found " .. strikeCount .. ")")

    -- Verify enemy took damage from all 6
    assert(world.enemies[1].hp == 14, "Enemy should take 36 damage (50 - 36 = 14)")

    print("✓ Distilled Chaos with Sacred Bark correctly plays 6 cards")
end

print("\n=== Test 4: Distilled Chaos plays X-cost card ===")
do
    local whirlwind = Utils.copyCardTemplate(Cards.Whirlwind)
    local strike = Utils.copyCardTemplate(Cards.Strike)

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        maxEnergy = 6,
        cards = {whirlwind, strike},
        masterPotions = {Potions.DistilledChaos}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Set enemy HP
    world.enemies[1].hp = 50
    world.enemies[1].maxHp = 50

    -- Player starts with 3 energy
    local initialEnergy = world.player.energy

    -- Clear log
    world.log = {}

    -- Use Distilled Chaos
    UsePotion.execute(world, world.player, 1)

    -- Verify Whirlwind was played
    assert(countLogEntries(world.log, "Whirlwind") > 0 or countLogEntries(world.log, "dealt 5 damage") > 0,
        "Whirlwind should be auto-played")

    -- Energy should NOT be spent (potion plays for free)
    assert(world.player.energy == initialEnergy, "Energy should not be spent")

    print("✓ Distilled Chaos with X-cost card works correctly")
end

print("\n=== All Distilled Chaos tests passed! ===")
