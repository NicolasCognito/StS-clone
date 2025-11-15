-- Test: Blue Candle Relic
-- Tests that Curse cards can be played with Blue Candle relic
-- and that they deal 1 HP damage and exhaust when played

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Relics = require("Data.relics")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
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

print("=== Blue Candle Relic Tests ===\n")

-- TEST 1: Curse cards are unplayable WITHOUT Blue Candle
print("Test 1: Curse cards unplayable without Blue Candle")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {Utils.copyCardTemplate(Cards.Clumsy)},
        relics = {}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local clumsy = world.player.combatDeck[1]
    assert(clumsy.state == "HAND", "Clumsy should be in hand")

    local result = playCardWithAutoContext(world, world.player, clumsy)

    -- Should fail to play
    assert(result ~= true, "Clumsy should not be playable without Blue Candle")
    assert(clumsy.state == "HAND", "Clumsy should still be in hand")
    assert(world.player.hp == 80, "Player HP should be unchanged")

    print("✓ Curse cards are unplayable without Blue Candle")
end

-- TEST 2: Curse cards ARE playable WITH Blue Candle
print("Test 2: Curse cards playable with Blue Candle")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {Utils.copyCardTemplate(Cards.Clumsy)},
        relics = {Relics.BlueCandle}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local initialHp = world.player.hp
    local clumsy = world.player.combatDeck[1]

    local result = playCardWithAutoContext(world, world.player, clumsy)

    -- Should play successfully
    assert(result == true, "Clumsy should be playable with Blue Candle")

    -- Should lose 1 HP
    assert(world.player.hp == initialHp - 1, "Player should lose 1 HP (expected " .. (initialHp - 1) .. ", got " .. world.player.hp .. ")")

    -- Should be exhausted
    assert(countCardsInState(world.player.combatDeck, "EXHAUSTED_PILE") == 1, "Clumsy should be exhausted")

    print("✓ Curse cards are playable with Blue Candle and deal 1 HP damage")
end

-- TEST 3: All Curse cards work with Blue Candle
print("Test 3: All Curse cards work with Blue Candle")
do
    local curses = {Cards.Clumsy, Cards.Decay, Cards.Normality, Cards.Pain}

    for _, curseTemplate in ipairs(curses) do
        local world = World.createWorld({
            id = "IronClad",
            maxHp = 80,
            currentHp = 80,
            maxEnergy = 6,
            cards = {Utils.copyCardTemplate(curseTemplate)},
            relics = {Relics.BlueCandle}
        })

        world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
        world.NoShuffle = true
        StartCombat.execute(world)

        local initialHp = world.player.hp
        local curse = world.player.combatDeck[1]

        local result = playCardWithAutoContext(world, world.player, curse)

        -- Should play successfully
        assert(result == true, curse.name .. " should be playable with Blue Candle")

        -- Should lose at least 1 HP (Pain loses 2 HP total: 1 from play + 1 from onExhaust)
        assert(world.player.hp < initialHp, curse.name .. " should cause HP loss")

        -- Should be exhausted
        assert(countCardsInState(world.player.combatDeck, "EXHAUSTED_PILE") == 1, curse.name .. " should be exhausted")

        print("  ✓ " .. curse.name .. " works with Blue Candle")
    end
end

-- TEST 4: Pain deals 2 HP total (1 from play + 1 from onExhaust)
print("Test 4: Pain deals 2 HP total (Blue Candle + onExhaust)")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {Utils.copyCardTemplate(Cards.Pain)},
        relics = {Relics.BlueCandle}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local initialHp = world.player.hp
    local pain = world.player.combatDeck[1]

    playCardWithAutoContext(world, world.player, pain)

    -- Should lose 2 HP total: 1 from Blue Candle play, 1 from onExhaust
    assert(world.player.hp == initialHp - 2, "Pain should deal 2 HP total (expected " .. (initialHp - 2) .. ", got " .. world.player.hp .. ")")

    print("✓ Pain deals 2 HP total (1 from Blue Candle + 1 from onExhaust)")
end

-- TEST 5: Multiple Curse cards can be played
print("Test 5: Multiple Curse cards can be played")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 6,
        cards = {
            Utils.copyCardTemplate(Cards.Clumsy),
            Utils.copyCardTemplate(Cards.Normality),
            Utils.copyCardTemplate(Cards.Decay)
        },
        relics = {Relics.BlueCandle}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local initialHp = world.player.hp

    -- Play all 3 curses
    for i = 1, 3 do
        local curse = nil
        for _, card in ipairs(world.player.combatDeck) do
            if card.state == "HAND" then
                curse = card
                break
            end
        end

        assert(curse ~= nil, "Should have a curse in hand")
        playCardWithAutoContext(world, world.player, curse)
    end

    -- Should lose 3 HP total
    assert(world.player.hp == initialHp - 3, "Should lose 3 HP total from 3 curses")

    -- All 3 should be exhausted
    assert(countCardsInState(world.player.combatDeck, "EXHAUSTED_PILE") == 3, "All 3 curses should be exhausted")

    print("✓ Multiple Curse cards can be played")
end

-- TEST 6: Curse cards cost 0 energy
print("Test 6: Curse cards cost 0 energy")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,  -- Low energy
        cards = {Utils.copyCardTemplate(Cards.Clumsy)},
        relics = {Relics.BlueCandle}
    })

    world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
    world.NoShuffle = true
    StartCombat.execute(world)

    local initialEnergy = world.player.energy
    local clumsy = world.player.combatDeck[1]

    playCardWithAutoContext(world, world.player, clumsy)

    -- Energy should be unchanged
    assert(world.player.energy == initialEnergy, "Playing Curse should not cost energy")

    print("✓ Curse cards cost 0 energy")
end

print("\n=== All Blue Candle tests passed! ===")
