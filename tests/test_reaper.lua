-- Test suite for Reaper card
-- Tests AOE damage + healing based on actual HP lost

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

local function findCardById(deck, id)
    for _, card in ipairs(deck) do
        if card.id == id then
            return card
        end
    end
    return nil
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

print("=== TEST REAPER CARD ===")

-- Test 1: Basic healing with multiple enemies
print("\n--- Test 1: Basic healing with multiple enemies ---")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 50,
        maxEnergy = 6,
        cards = {copyCard(Cards.Reaper)},
        relics = {}
    })

    world.enemies = {
        copyEnemy(Enemies.Cultist),
        copyEnemy(Enemies.Cultist),
        copyEnemy(Enemies.Cultist)
    }
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Set all enemies to 10 HP
    for _, enemy in ipairs(world.enemies) do
        enemy.hp = 10
        enemy.maxHp = 10
    end

    local playerHpBefore = world.player.hp

    local reaper = findCardById(world.player.combatDeck, "Reaper")
    assert(reaper, "Reaper card not found")

    playCardWithAutoContext(world, world.player, reaper)

    -- Each enemy takes 4 damage, 3 enemies = 12 total HP lost
    -- Player should heal 12 HP
    local expectedHealing = 12
    local actualHealing = world.player.hp - playerHpBefore

    print("Player HP before: " .. playerHpBefore)
    print("Player HP after: " .. world.player.hp)
    print("Expected healing: " .. expectedHealing)
    print("Actual healing: " .. actualHealing)

    assert(actualHealing == expectedHealing, "Expected healing " .. expectedHealing .. ", got " .. actualHealing)

    -- Verify enemies took damage
    for i, enemy in ipairs(world.enemies) do
        print("Enemy " .. i .. " HP: " .. enemy.hp .. " (expected 6)")
        assert(enemy.hp == 6, "Enemy should have 6 HP after taking 4 damage")
    end

    -- Verify card exhausted
    local exhaustedCount = countCardsInState(world.player.combatDeck, "EXHAUSTED_PILE")
    assert(exhaustedCount == 1, "Reaper should be exhausted")

    print("✓ Test 1 passed: Basic healing with multiple enemies")
end

-- Test 2: Overkill doesn't give extra healing
print("\n--- Test 2: Overkill doesn't give extra healing ---")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 50,
        maxEnergy = 6,
        cards = {copyCard(Cards.Reaper)},
        relics = {}
    })

    world.enemies = {
        copyEnemy(Enemies.Cultist),
        copyEnemy(Enemies.Cultist)
    }
    world.NoShuffle = true
    StartCombat.execute(world)

    -- First enemy has 2 HP (overkill), second has 10 HP
    world.enemies[1].hp = 2
    world.enemies[1].maxHp = 10
    world.enemies[2].hp = 10
    world.enemies[2].maxHp = 10

    local playerHpBefore = world.player.hp

    local reaper = findCardById(world.player.combatDeck, "Reaper")
    playCardWithAutoContext(world, world.player, reaper)

    -- Enemy 1: only 2 HP to lose (overkill damage doesn't heal)
    -- Enemy 2: 4 HP lost
    -- Total healing: 2 + 4 = 6
    local expectedHealing = 6
    local actualHealing = world.player.hp - playerHpBefore

    print("Player HP before: " .. playerHpBefore)
    print("Player HP after: " .. world.player.hp)
    print("Expected healing: " .. expectedHealing)
    print("Actual healing: " .. actualHealing)

    assert(actualHealing == expectedHealing, "Overkill should not give extra healing")
    assert(world.enemies[1].hp == 0, "Enemy 1 should be dead")
    assert(world.enemies[2].hp == 6, "Enemy 2 should have 6 HP")

    print("✓ Test 2 passed: Overkill doesn't give extra healing")
end

-- Test 3: Block reduces healing
print("\n--- Test 3: Block reduces healing ---")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 50,
        maxEnergy = 6,
        cards = {copyCard(Cards.Reaper)},
        relics = {}
    })

    world.enemies = {copyEnemy(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    world.enemies[1].hp = 10
    world.enemies[1].maxHp = 10
    world.enemies[1].block = 2  -- 2 damage blocked

    local playerHpBefore = world.player.hp

    local reaper = findCardById(world.player.combatDeck, "Reaper")
    playCardWithAutoContext(world, world.player, reaper)

    -- Damage: 4, Block: 2, HP lost: 2
    local expectedHealing = 2
    local actualHealing = world.player.hp - playerHpBefore

    print("Player HP before: " .. playerHpBefore)
    print("Player HP after: " .. world.player.hp)
    print("Expected healing: " .. expectedHealing)
    print("Actual healing: " .. actualHealing)

    assert(actualHealing == expectedHealing, "Blocked damage should not heal")
    assert(world.enemies[1].hp == 8, "Enemy should have 8 HP (10 - 2 unblocked)")

    print("✓ Test 3 passed: Block reduces healing")
end

-- Test 4: Strength increases damage and healing
print("\n--- Test 4: Strength increases damage and healing ---")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 50,
        maxEnergy = 6,
        cards = {copyCard(Cards.Reaper)},
        relics = {}
    })

    world.enemies = {
        copyEnemy(Enemies.Cultist),
        copyEnemy(Enemies.Cultist)
    }
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Give player 3 strength
    world.player.status = {strength = 3}

    for _, enemy in ipairs(world.enemies) do
        enemy.hp = 20
        enemy.maxHp = 20
    end

    local playerHpBefore = world.player.hp

    local reaper = findCardById(world.player.combatDeck, "Reaper")
    playCardWithAutoContext(world, world.player, reaper)

    -- Damage with strength: 4 + 3 = 7 per enemy
    -- 2 enemies = 14 total healing
    local expectedHealing = 14
    local actualHealing = world.player.hp - playerHpBefore

    print("Player HP before: " .. playerHpBefore)
    print("Player HP after: " .. world.player.hp)
    print("Expected healing: " .. expectedHealing)
    print("Actual healing: " .. actualHealing)

    assert(actualHealing == expectedHealing, "Strength should increase healing")

    for _, enemy in ipairs(world.enemies) do
        assert(enemy.hp == 13, "Enemy should have 13 HP (20 - 7)")
    end

    print("✓ Test 4 passed: Strength increases damage and healing")
end

-- Test 5: Upgraded Reaper (cost 1, damage 5)
print("\n--- Test 5: Upgraded Reaper ---")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 50,
        maxEnergy = 6,
        cards = {copyCard(Cards.Reaper)},
        relics = {}
    })

    world.enemies = {
        copyEnemy(Enemies.Cultist),
        copyEnemy(Enemies.Cultist)
    }
    world.NoShuffle = true

    -- Upgrade the card before combat
    local reaper = world.player.masterDeck[1]
    reaper:onUpgrade()

    StartCombat.execute(world)

    for _, enemy in ipairs(world.enemies) do
        enemy.hp = 20
        enemy.maxHp = 20
    end

    local playerHpBefore = world.player.hp
    local energyBefore = world.player.energy

    local reaperUpgraded = findCardById(world.player.combatDeck, "Reaper")
    assert(reaperUpgraded.upgraded, "Reaper should be upgraded")
    assert(reaperUpgraded.cost == 1, "Upgraded Reaper should cost 1")
    assert(reaperUpgraded.damage == 5, "Upgraded Reaper should deal 5 damage")

    playCardWithAutoContext(world, world.player, reaperUpgraded)

    -- Damage: 5 per enemy, 2 enemies = 10 total healing
    local expectedHealing = 10
    local actualHealing = world.player.hp - playerHpBefore

    print("Player HP before: " .. playerHpBefore)
    print("Player HP after: " .. world.player.hp)
    print("Expected healing: " .. expectedHealing)
    print("Actual healing: " .. actualHealing)
    print("Energy spent: " .. (energyBefore - world.player.energy))

    assert(actualHealing == expectedHealing, "Upgraded Reaper should heal 10")
    assert(world.player.energy == energyBefore - 1, "Upgraded Reaper should cost 1 energy")

    for _, enemy in ipairs(world.enemies) do
        assert(enemy.hp == 15, "Enemy should have 15 HP (20 - 5)")
    end

    print("✓ Test 5 passed: Upgraded Reaper")
end

-- Test 6: Healing capped at max HP
print("\n--- Test 6: Healing capped at max HP ---")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 75,  -- Close to max HP
        maxEnergy = 6,
        cards = {copyCard(Cards.Reaper)},
        relics = {}
    })

    world.enemies = {
        copyEnemy(Enemies.Cultist),
        copyEnemy(Enemies.Cultist)
    }
    world.NoShuffle = true
    StartCombat.execute(world)

    for _, enemy in ipairs(world.enemies) do
        enemy.hp = 20
        enemy.maxHp = 20
    end

    local playerHpBefore = world.player.hp

    local reaper = findCardById(world.player.combatDeck, "Reaper")
    playCardWithAutoContext(world, world.player, reaper)

    -- Total healing would be 8, but player only has room for 5 HP
    -- Player should be at max HP (80)
    assert(world.player.hp == world.player.maxHp, "Healing should cap at max HP")

    local actualHealing = world.player.hp - playerHpBefore
    print("Player HP before: " .. playerHpBefore)
    print("Player HP after: " .. world.player.hp)
    print("Actual healing: " .. actualHealing .. " (capped at max HP)")

    print("✓ Test 6 passed: Healing capped at max HP")
end

print("\n=== ALL REAPER TESTS PASSED ===")
