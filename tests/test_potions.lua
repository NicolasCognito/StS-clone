local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Potions = require("Data.potions")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local UsePotion = require("Pipelines.UsePotion")

math.randomseed(1337)

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

local function copyPotion(template)
    local potion = {}
    for k, v in pairs(template) do
        potion[k] = v
    end
    return potion
end

-- Test 1: Health Potion should heal player
do
    print("\n=== TEST 1: Health Potion ===")

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 50,  -- Start with reduced HP
        cards = {copyCard(Cards.Strike)},
        relics = {},
        masterPotions = {copyPotion(Potions.HealthPotion)}
    })

    world.enemies = {copyEnemy(Enemies.Goblin)}
    StartCombat.execute(world)

    local player = world.player
    assert(player.hp == 50, "Player should start with 50 HP")
    assert(#player.masterPotions == 1, "Player should have 1 potion")

    local potion = player.masterPotions[1]
    assert(potion.id == "HealthPotion", "Potion should be HealthPotion")

    -- Use the health potion
    UsePotion.execute(world, player, potion)

    -- Verify healing
    assert(player.hp == 70, "Player should have 70 HP after healing 20 (was " .. player.hp .. ")")
    assert(#player.masterPotions == 0, "Potion should be consumed (was " .. #player.masterPotions .. ")")

    print("✓ Health Potion heals correctly and is consumed")
end

-- Test 2: Block Potion should give block
do
    print("\n=== TEST 2: Block Potion ===")

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        cards = {copyCard(Cards.Strike)},
        relics = {},
        masterPotions = {copyPotion(Potions.BlockPotion)}
    })

    world.enemies = {copyEnemy(Enemies.Goblin)}
    StartCombat.execute(world)

    local player = world.player
    assert(player.block == 0, "Player should start with 0 block")
    assert(#player.masterPotions == 1, "Player should have 1 potion")

    -- Use the block potion
    local potion = player.masterPotions[1]
    UsePotion.execute(world, player, potion)

    -- Verify block gain
    assert(player.block == 12, "Player should have 12 block (was " .. player.block .. ")")
    assert(#player.masterPotions == 0, "Potion should be consumed")

    print("✓ Block Potion gives block correctly and is consumed")
end

-- Test 3: Strength Potion should give strength
do
    print("\n=== TEST 3: Strength Potion ===")

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        cards = {copyCard(Cards.Strike)},
        relics = {},
        masterPotions = {copyPotion(Potions.StrengthPotion)}
    })

    world.enemies = {copyEnemy(Enemies.Goblin)}
    StartCombat.execute(world)

    local player = world.player
    assert(not player.status or not player.status.strength or player.status.strength == 0, "Player should start with 0 strength")

    -- Use the strength potion
    local potion = player.masterPotions[1]
    UsePotion.execute(world, player, potion)

    -- Verify strength gain
    assert(player.status and player.status.strength == 2, "Player should have 2 strength (was " .. tostring(player.status and player.status.strength) .. ")")
    assert(#player.masterPotions == 0, "Potion should be consumed")

    print("✓ Strength Potion gives strength correctly and is consumed")
end

-- Test 4: Fire Potion should damage all enemies
do
    print("\n=== TEST 4: Fire Potion ===")

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        cards = {copyCard(Cards.Strike)},
        relics = {},
        masterPotions = {copyPotion(Potions.FirePotion)}
    })

    -- Create two enemies
    world.enemies = {copyEnemy(Enemies.Goblin), copyEnemy(Enemies.Goblin)}
    StartCombat.execute(world)

    local player = world.player
    local enemy1 = world.enemies[1]
    local enemy2 = world.enemies[2]

    -- Give enemies enough HP to survive Fire Potion (15 damage)
    enemy1.hp = 20
    enemy1.maxHp = 20
    enemy2.hp = 20
    enemy2.maxHp = 20

    local initialHp1 = enemy1.hp
    local initialHp2 = enemy2.hp

    -- Use the fire potion
    local potion = player.masterPotions[1]
    UsePotion.execute(world, player, potion)

    -- Verify damage to all enemies
    assert(enemy1.hp == initialHp1 - 15, "Enemy 1 should take 15 damage (was " .. (initialHp1 - enemy1.hp) .. ")")
    assert(enemy2.hp == initialHp2 - 15, "Enemy 2 should take 15 damage (was " .. (initialHp2 - enemy2.hp) .. ")")
    assert(#player.masterPotions == 0, "Potion should be consumed")

    print("✓ Fire Potion damages all enemies correctly and is consumed")
end

print("\n=== ALL POTION TESTS PASSED ===\n")
