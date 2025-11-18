-- Test: Status Cards
-- Tests all 5 Status cards: Wound, Void, Burn, Dazed, Slimed

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local DrawCard = require("Pipelines.DrawCard")
local EndTurn = require("Pipelines.EndTurn")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")

math.randomseed(1337)

local function playCardWithAutoContext(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            return true
        elseif result == false then
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

local function countCardsInState(deck, state)
    local count = 0
    for _, card in ipairs(deck) do
        if card.state == state then
            count = count + 1
        end
    end
    return count
end

print("=== Status Cards Tests ===\n")

-- TEST 1: Wound - unplayable, just clogs deck
print("Test 1: Wound is unplayable")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        cards = {Utils.copyCardTemplate(Cards.Wound)},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local wound = world.player.combatDeck[1]
    assert(wound.state == "HAND", "Wound should be in hand")
    assert(wound.unplayable == true, "Wound should be unplayable")
    assert(wound.cost == -2, "Wound should cost -2")

    print("✓ Wound is unplayable and clogs deck")
end

-- TEST 2: Void - loses 1 energy when drawn
print("Test 2: Void loses 1 energy when drawn")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        cards = {},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    StartCombat.execute(world)

    -- Add Void to deck
    local voidCard = Utils.copyCardTemplate(Cards.Void)
    voidCard.state = "DECK"
    table.insert(world.player.combatDeck, voidCard)

    local initialEnergy = world.player.energy
    assert(initialEnergy == 3, "Player should start with 3 energy")

    -- Draw Void
    DrawCard.execute(world, world.player, 1)

    -- Should have lost 1 energy
    assert(world.player.energy == initialEnergy - 1, "Player should lose 1 energy when drawing Void (expected " .. (initialEnergy - 1) .. ", got " .. world.player.energy .. ")")
    assert(voidCard.state == "HAND", "Void should be in hand after drawing")

    print("✓ Void loses 1 energy when drawn")
end

-- TEST 3: Void doesn't reduce energy below 0
print("Test 3: Void doesn't reduce energy below 0")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        cards = {},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    StartCombat.execute(world)

    -- Set energy to 0
    world.player.energy = 0

    -- Add Void to deck
    local voidCard = Utils.copyCardTemplate(Cards.Void)
    voidCard.state = "DECK"
    table.insert(world.player.combatDeck, voidCard)

    -- Draw Void
    DrawCard.execute(world, world.player, 1)

    -- Energy should still be 0 (not negative)
    assert(world.player.energy == 0, "Energy should not go below 0 (got " .. world.player.energy .. ")")

    print("✓ Void doesn't reduce energy below 0")
end

-- TEST 4: Void is ethereal (removed at end of turn)
print("Test 4: Void is ethereal")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        cards = {Utils.copyCardTemplate(Cards.Void)},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local voidCard = world.player.combatDeck[1]
    assert(voidCard.ethereal == true, "Void should be ethereal")
    assert(voidCard.state == "HAND", "Void should be in hand")

    print("✓ Void is ethereal")
end

-- TEST 5: Burn - deals 2 damage at end of turn
print("Test 5: Burn deals 2 damage at end of turn")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        cards = {Utils.copyCardTemplate(Cards.Burn)},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local burn = world.player.combatDeck[1]
    assert(burn.state == "HAND", "Burn should be in hand")

    local initialHp = world.player.hp
    assert(initialHp == 80, "Player should start with 80 HP")

    -- End turn (should trigger Burn's onEndOfTurn hook)
    EndTurn.execute(world, world.player)

    -- Should have taken 2 damage
    assert(world.player.hp == initialHp - 2, "Player should take 2 damage from Burn at end of turn (expected " .. (initialHp - 2) .. ", got " .. world.player.hp .. ")")

    print("✓ Burn deals 2 damage at end of turn")
end

-- TEST 6: Burn+ - deals 4 damage at end of turn (upgraded)
print("Test 6: Burn+ deals 4 damage at end of turn")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        cards = {},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    StartCombat.execute(world)

    -- Add upgraded Burn
    local burn = Utils.copyCardTemplate(Cards.Burn)
    burn:onUpgrade()
    burn.state = "HAND"
    table.insert(world.player.combatDeck, burn)

    local initialHp = world.player.hp
    assert(burn.damage == 4, "Upgraded Burn should deal 4 damage")

    -- End turn (should trigger Burn's onEndOfTurn hook)
    EndTurn.execute(world, world.player)

    -- Should have taken 4 damage
    assert(world.player.hp == initialHp - 4, "Player should take 4 damage from Burn+ at end of turn (expected " .. (initialHp - 4) .. ", got " .. world.player.hp .. ")")

    print("✓ Burn+ deals 4 damage at end of turn")
end

-- TEST 7: Multiple Burns stack
print("Test 7: Multiple Burns stack damage at end of turn")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        cards = {
            Utils.copyCardTemplate(Cards.Burn),
            Utils.copyCardTemplate(Cards.Burn),
            Utils.copyCardTemplate(Cards.Burn)
        },
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local initialHp = world.player.hp

    -- End turn (should trigger all 3 Burns)
    EndTurn.execute(world, world.player)

    -- Should have taken 6 damage (3 * 2)
    assert(world.player.hp == initialHp - 6, "Player should take 6 damage from 3 Burns (expected " .. (initialHp - 6) .. ", got " .. world.player.hp .. ")")

    print("✓ Multiple Burns stack damage")
end

-- TEST 8: Burn in discard doesn't trigger
print("Test 8: Burn in discard pile doesn't trigger at end of turn")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        cards = {},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    StartCombat.execute(world)

    -- Add Burn to discard pile
    local burn = Utils.copyCardTemplate(Cards.Burn)
    burn.state = "DISCARD_PILE"
    table.insert(world.player.combatDeck, burn)

    local initialHp = world.player.hp

    -- End turn
    EndTurn.execute(world, world.player)

    -- Should NOT take damage (Burn not in hand)
    assert(world.player.hp == initialHp, "Player should not take damage from Burn in discard pile")

    print("✓ Burn in discard pile doesn't trigger")
end

-- TEST 9: Dazed - unplayable + ethereal
print("Test 9: Dazed is unplayable and ethereal")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        cards = {Utils.copyCardTemplate(Cards.Dazed)},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local dazed = world.player.combatDeck[1]
    assert(dazed.state == "HAND", "Dazed should be in hand")
    assert(dazed.unplayable == true, "Dazed should be unplayable")
    assert(dazed.ethereal == true, "Dazed should be ethereal")
    assert(dazed.cost == -2, "Dazed should cost -2")

    print("✓ Dazed is unplayable and ethereal")
end

-- TEST 10: Slimed - playable, costs 1, exhausts
print("Test 10: Slimed is playable, costs 1 energy, and exhausts")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        cards = {Utils.copyCardTemplate(Cards.Slimed)},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local slimed = world.player.combatDeck[1]
    assert(slimed.state == "HAND", "Slimed should be in hand")
    assert(slimed.cost == 1, "Slimed should cost 1 energy")
    assert(slimed.exhausts == true, "Slimed should exhaust")
    assert(slimed.unplayable == nil or slimed.unplayable == false, "Slimed should be playable")

    local initialEnergy = world.player.energy
    local initialHp = world.player.hp

    -- Play Slimed
    local result = playCardWithAutoContext(world, world.player, slimed)

    -- Should play successfully
    assert(result == true, "Slimed should be playable")

    -- Should cost 1 energy
    assert(world.player.energy == initialEnergy - 1, "Slimed should cost 1 energy (expected " .. (initialEnergy - 1) .. ", got " .. world.player.energy .. ")")

    -- Should not affect HP
    assert(world.player.hp == initialHp, "Slimed should not affect HP")

    -- Should be exhausted
    assert(countCardsInState(world.player.combatDeck, "EXHAUSTED_PILE") == 1, "Slimed should be exhausted")

    print("✓ Slimed is playable, costs 1 energy, and exhausts")
end

-- TEST 11: All Status cards have correct type and character
print("Test 11: All Status cards have correct type and character")
do
    local statusCards = {Cards.Wound, Cards.Void, Cards.Burn, Cards.Dazed, Cards.Slimed}
    local statusNames = {"Wound", "Void", "Burn", "Dazed", "Slimed"}

    for i, card in ipairs(statusCards) do
        assert(card.type == "STATUS", statusNames[i] .. " should have type STATUS")
        assert(card.character == "COLORLESS", statusNames[i] .. " should be COLORLESS")
        assert(card.rarity == "COMMON", statusNames[i] .. " should be COMMON rarity")
        print("  ✓ " .. statusNames[i] .. " has correct type/character/rarity")
    end
end

print("\n=== All Status Cards tests passed! ===")
