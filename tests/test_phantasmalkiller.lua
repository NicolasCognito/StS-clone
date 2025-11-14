-- TEST: Phantasmal Killer Card
-- Tests the Phantasmal Killer mechanic:
-- 1. Applies phantasmal status when played
-- 2. Converts to double_damage at start of next turn
-- 3. All attacks deal double damage while active
-- 4. double_damage ticks down by 1 each round
-- 5. Stacking multiple Phantasmal Killers works correctly

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")
local StartTurn = require("Pipelines.StartTurn")
local EndTurn = require("Pipelines.EndTurn")
local EndRound = require("Pipelines.EndRound")

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

local function findCardById(deck, cardId)
    for _, card in ipairs(deck) do
        if card.id == cardId and card.state == "HAND" then
            return card
        end
    end
    return nil
end

print("\n=== TEST 1: Basic Phantasmal Killer Functionality ===")
do
    local world = World.createWorld({
        id = "SILENT",
        maxHp = 80,
        maxEnergy = 6,
        cards = {
            copyCard(Cards.PhantasmalKiller),
            copyCard(Cards.Strike_G)
        },
        relics = {}
    })

    world.enemies = {copyEnemy(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Set up enemy HP
    world.enemies[1].hp = 30
    world.enemies[1].maxHp = 30

    -- Play Phantasmal Killer
    local pk = findCardById(world.player.combatDeck, "Phantasmal_Killer")
    assert(pk, "Phantasmal Killer should be in hand")
    playCardWithAutoContext(world, world.player, pk)

    -- Check phantasmal status applied
    assert(world.player.status.phantasmal == 1, "Should have 1 phantasmal stack")
    assert(not world.player.status.double_damage or world.player.status.double_damage == 0, "Should not have double_damage yet")

    print("✓ Phantasmal status applied correctly")

    -- End turn and start new turn
    EndTurn.execute(world, world.player)
    StartTurn.execute(world, world.player)

    -- Check conversion to double_damage
    assert(world.player.status.phantasmal == 0, "Phantasmal should be consumed")
    assert(world.player.status.double_damage == 1, "Should have 1 double_damage stack")

    print("✓ Phantasmal converted to double_damage at start of turn")

    -- Play Strike (6 damage base)
    local strike = findCardById(world.player.combatDeck, "Strike_G")
    assert(strike, "Strike should be in hand")

    local enemyHpBefore = world.enemies[1].hp
    playCardWithAutoContext(world, world.player, strike)
    local enemyHpAfter = world.enemies[1].hp

    local damageDealt = enemyHpBefore - enemyHpAfter
    assert(damageDealt == 12, "Strike should deal 12 damage (6 × 2), dealt: " .. damageDealt)

    print("✓ Attack dealt double damage")

    -- End turn and round to tick down double_damage
    EndTurn.execute(world, world.player)
    EndRound.execute(world)

    -- Check double_damage ticked down
    assert(world.player.status.double_damage == 0, "double_damage should tick down to 0")

    print("✓ double_damage ticked down correctly")
end

print("\n=== TEST 2: Stacking Multiple Phantasmal Killers ===")
do
    local world = World.createWorld({
        id = "SILENT",
        maxHp = 80,
        maxEnergy = 6,
        cards = {
            copyCard(Cards.PhantasmalKiller),
            copyCard(Cards.PhantasmalKiller),
            copyCard(Cards.Strike_G)
        },
        relics = {}
    })

    world.enemies = {copyEnemy(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    world.enemies[1].hp = 50
    world.enemies[1].maxHp = 50

    -- Play Phantasmal Killer twice
    for i = 1, 2 do
        local pk = findCardById(world.player.combatDeck, "Phantasmal_Killer")
        assert(pk, "Phantasmal Killer " .. i .. " should be in hand")
        playCardWithAutoContext(world, world.player, pk)
    end

    -- Check stacking
    assert(world.player.status.phantasmal == 2, "Should have 2 phantasmal stacks")

    print("✓ Multiple Phantasmal Killers stack correctly")

    -- Start next turn
    EndTurn.execute(world, world.player)
    StartTurn.execute(world, world.player)

    -- Check conversion
    assert(world.player.status.phantasmal == 0, "Phantasmal should be consumed")
    assert(world.player.status.double_damage == 2, "Should have 2 double_damage stacks")

    print("✓ Phantasmal stacks converted to double_damage")

    -- Play Strike
    local strike = findCardById(world.player.combatDeck, "Strike_G")
    local enemyHpBefore = world.enemies[1].hp
    playCardWithAutoContext(world, world.player, strike)
    local damageDealt = enemyHpBefore - world.enemies[1].hp

    assert(damageDealt == 12, "Strike should still deal 12 damage (6 × 2), dealt: " .. damageDealt)

    print("✓ Attack dealt double damage with 2 stacks")

    -- End round - should tick down by 1
    EndTurn.execute(world, world.player)
    EndRound.execute(world)

    assert(world.player.status.double_damage == 1, "double_damage should tick down to 1")

    print("✓ double_damage ticked down from 2 to 1")

    -- Next turn - should still have double damage
    StartTurn.execute(world, world.player)

    strike = findCardById(world.player.combatDeck, "Strike_G")
    enemyHpBefore = world.enemies[1].hp
    playCardWithAutoContext(world, world.player, strike)
    damageDealt = enemyHpBefore - world.enemies[1].hp

    assert(damageDealt == 12, "Strike should still deal 12 damage (6 × 2), dealt: " .. damageDealt)

    print("✓ Attack still dealt double damage after tick down")

    -- End round again
    EndTurn.execute(world, world.player)
    EndRound.execute(world)

    assert(world.player.status.double_damage == 0, "double_damage should tick down to 0")

    print("✓ double_damage fully consumed after 2 rounds")
end

print("\n=== TEST 3: Multiple Attacks in One Turn ===")
do
    local world = World.createWorld({
        id = "SILENT",
        maxHp = 80,
        maxEnergy = 6,
        cards = {
            copyCard(Cards.PhantasmalKiller),
            copyCard(Cards.Strike_G),
            copyCard(Cards.Strike_G),
            copyCard(Cards.Strike_G)
        },
        relics = {}
    })

    world.enemies = {copyEnemy(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    world.enemies[1].hp = 50
    world.enemies[1].maxHp = 50

    -- Play Phantasmal Killer
    local pk = findCardById(world.player.combatDeck, "Phantasmal_Killer")
    playCardWithAutoContext(world, world.player, pk)

    -- Start next turn
    EndTurn.execute(world, world.player)
    StartTurn.execute(world, world.player)

    -- Play 3 Strikes
    local totalDamage = 0
    for i = 1, 3 do
        local strike = findCardById(world.player.combatDeck, "Strike_G")
        if strike then
            local hpBefore = world.enemies[1].hp
            playCardWithAutoContext(world, world.player, strike)
            totalDamage = totalDamage + (hpBefore - world.enemies[1].hp)
        end
    end

    assert(totalDamage == 36, "Total damage should be 36 (3 × 12), dealt: " .. totalDamage)

    print("✓ All attacks in one turn dealt double damage")
end

print("\n=== TEST 4: Interaction with Vulnerable ===")
do
    local world = World.createWorld({
        id = "SILENT",
        maxHp = 80,
        maxEnergy = 6,
        cards = {
            copyCard(Cards.PhantasmalKiller),
            copyCard(Cards.Strike_G)
        },
        relics = {}
    })

    world.enemies = {copyEnemy(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    world.enemies[1].hp = 50
    world.enemies[1].maxHp = 50
    world.enemies[1].status = {vulnerable = 2}

    -- Play Phantasmal Killer
    local pk = findCardById(world.player.combatDeck, "Phantasmal_Killer")
    playCardWithAutoContext(world, world.player, pk)

    -- Start next turn
    EndTurn.execute(world, world.player)
    StartTurn.execute(world, world.player)

    -- Play Strike with vulnerable
    local strike = findCardById(world.player.combatDeck, "Strike_G")
    local hpBefore = world.enemies[1].hp
    playCardWithAutoContext(world, world.player, strike)
    local damageDealt = hpBefore - world.enemies[1].hp

    -- Expected: 6 base × 1.5 (vulnerable) = 9, then × 2 (double_damage) = 18
    assert(damageDealt == 18, "Strike should deal 18 damage (6 × 1.5 × 2), dealt: " .. damageDealt)

    print("✓ Double damage stacks multiplicatively with vulnerable")
end

print("\n=== TEST 5: Upgraded Phantasmal Killer Costs 0 ===")
do
    local world = World.createWorld({
        id = "SILENT",
        maxHp = 80,
        maxEnergy = 3,
        cards = {copyCard(Cards.PhantasmalKiller)},
        relics = {}
    })

    world.enemies = {copyEnemy(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Find and upgrade the card
    local pk = findCardById(world.player.combatDeck, "Phantasmal_Killer")
    assert(pk, "Phantasmal Killer should exist")

    pk:onUpgrade()

    assert(pk.cost == 0, "Upgraded Phantasmal Killer should cost 0")
    assert(pk.upgraded == true, "Should be marked as upgraded")

    print("✓ Upgraded Phantasmal Killer costs 0 energy")

    -- Play it with only 1 energy
    world.player.energy = 1
    local energyBefore = world.player.energy
    playCardWithAutoContext(world, world.player, pk)

    assert(world.player.energy == energyBefore, "Should not consume energy")
    assert(world.player.status.phantasmal == 1, "Should apply phantasmal")

    print("✓ Upgraded card plays for free")
end

print("\n=== TEST 6: Adding Phantasmal While Double Damage is Active ===")
do
    local world = World.createWorld({
        id = "SILENT",
        maxHp = 80,
        maxEnergy = 6,
        cards = {
            copyCard(Cards.PhantasmalKiller),
            copyCard(Cards.PhantasmalKiller)
        },
        relics = {}
    })

    world.enemies = {copyEnemy(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    -- Play first Phantasmal Killer
    local pk1 = findCardById(world.player.combatDeck, "Phantasmal_Killer")
    playCardWithAutoContext(world, world.player, pk1)

    -- Start next turn - double_damage = 1
    EndTurn.execute(world, world.player)
    StartTurn.execute(world, world.player)

    assert(world.player.status.double_damage == 1, "Should have double_damage")

    -- Play second Phantasmal Killer while double_damage is active
    local pk2 = findCardById(world.player.combatDeck, "Phantasmal_Killer")
    playCardWithAutoContext(world, world.player, pk2)

    assert(world.player.status.phantasmal == 1, "Should have new phantasmal stack")
    assert(world.player.status.double_damage == 1, "Should still have double_damage")

    print("✓ Can add phantasmal while double_damage is active")

    -- End round - double_damage ticks down to 0
    EndTurn.execute(world, world.player)
    EndRound.execute(world)

    assert(world.player.status.double_damage == 0, "double_damage should tick down")

    -- Next turn - phantasmal converts
    StartTurn.execute(world, world.player)

    assert(world.player.status.double_damage == 1, "Should have double_damage from phantasmal")
    assert(world.player.status.phantasmal == 0, "Phantasmal should be consumed")

    print("✓ Phantasmal converted correctly after double_damage expired")
end

print("\n=== ALL PHANTASMAL KILLER TESTS PASSED ===\n")
