-- TEST: STABLE CONTEXT VALIDATION
-- Verifies that cards with stableContextValidator properly cancel when context becomes invalid
-- Example: Double Tap + Strike where enemy dies after first strike

package.path = package.path .. ";../?.lua"

local World = require("World")
local CombatEngine = require("CombatEngine")
local CardLoader = require("CardLoader")

local function createTestWorld()
    local world = World.new()
    world.player = {
        id = "Player",
        name = "Ironclad",
        hp = 80,
        maxHP = 80,
        block = 0,
        energy = 3,
        maxEnergy = 3,
        masterDeck = {},
        relics = {}
    }

    -- Enemy with 5 HP (will die from first Strike which deals 6 damage)
    world.enemies = {
        {
            id = "cultist1",
            name = "Cultist",
            hp = 5,
            maxHP = 48,
            block = 0,
            intent = "ATTACK_6",
            damage = 6
        }
    }

    return world
end

local function testStrikeWithDoubleTapKillsEnemy()
    print("\n=== TEST: Strike with Double Tap kills enemy before duplication ===")

    local world = createTestWorld()
    local strike = CardLoader.cloneCard("Strike")
    local doubleTap = CardLoader.cloneCard("Double_Tap")

    -- Add cards to hand
    strike.state = "HAND"
    doubleTap.state = "HAND"
    table.insert(world.player.masterDeck, strike)
    table.insert(world.player.masterDeck, doubleTap)

    local handlers = {
        onPlayerAction = function(world)
            -- First play Double Tap
            if doubleTap.state == "HAND" then
                return {type = "play", card = doubleTap}
            end
            -- Then play Strike (will be duplicated by Double Tap)
            if strike.state == "HAND" then
                return {type = "play", card = strike}
            end
            return {type = "end"}
        end,

        onContextRequest = function(world, request)
            -- Auto-select the only enemy
            if request.contextProvider.type == "enemy" then
                return world.enemies[1], nil
            end
            return nil, nil
        end,

        onRenderState = function(world) end,
        onDisplayLog = function(world, count) end,
        onCombatResult = function(world, result) end,
        onCombatEnd = function(world, result) end
    }

    CombatEngine.playGame(world, handlers)

    -- Verify results
    print("\n--- Verification ---")
    print("Enemy HP: " .. world.enemies[1].hp .. " (should be <= 0)")
    print("Enemy should be dead: " .. tostring(world.enemies[1].hp <= 0))

    -- Check logs for cancellation message
    local foundCancellation = false
    local foundDuplication = false
    for _, logEntry in ipairs(world.log) do
        if string.match(logEntry, "canceled.*target no longer valid") then
            foundCancellation = true
        end
        if string.match(logEntry, "Double Tap triggers") then
            foundDuplication = true
        end
    end

    print("Found duplication trigger: " .. tostring(foundDuplication))
    print("Found cancellation message: " .. tostring(foundCancellation))

    -- Print last 20 log entries
    print("\n--- Last 20 Log Entries ---")
    local startIdx = math.max(1, #world.log - 19)
    for i = startIdx, #world.log do
        print(world.log[i])
    end

    -- Assertions
    assert(world.enemies[1].hp <= 0, "Enemy should be dead")
    assert(foundDuplication, "Should find Double Tap trigger in logs")
    assert(foundCancellation, "Should find cancellation message in logs")

    print("\n✓ Test passed!")
end

local function testStrikeWithDoubleTapBothHit()
    print("\n=== TEST: Strike with Double Tap where both strikes hit ===")

    local world = createTestWorld()
    -- Enemy with enough HP to survive first strike
    world.enemies[1].hp = 15
    world.enemies[1].maxHP = 15

    local strike = CardLoader.cloneCard("Strike")
    local doubleTap = CardLoader.cloneCard("Double_Tap")

    -- Add cards to hand
    strike.state = "HAND"
    doubleTap.state = "HAND"
    table.insert(world.player.masterDeck, strike)
    table.insert(world.player.masterDeck, doubleTap)

    local handlers = {
        onPlayerAction = function(world)
            if doubleTap.state == "HAND" then
                return {type = "play", card = doubleTap}
            end
            if strike.state == "HAND" then
                return {type = "play", card = strike}
            end
            return {type = "end"}
        end,

        onContextRequest = function(world, request)
            if request.contextProvider.type == "enemy" then
                return world.enemies[1], nil
            end
            return nil, nil
        end,

        onRenderState = function(world) end,
        onDisplayLog = function(world, count) end,
        onCombatResult = function(world, result) end,
        onCombatEnd = function(world, result) end
    }

    CombatEngine.playGame(world, handlers)

    -- Verify results
    print("\n--- Verification ---")
    print("Enemy HP: " .. world.enemies[1].hp .. " (should be 3: 15 - 6 - 6)")

    -- Check logs - should NOT have cancellation
    local foundCancellation = false
    local strikeCount = 0
    for _, logEntry in ipairs(world.log) do
        if string.match(logEntry, "canceled.*target no longer valid") then
            foundCancellation = true
        end
        if string.match(logEntry, "dealt 6 damage") then
            strikeCount = strikeCount + 1
        end
    end

    print("Number of strikes that dealt damage: " .. strikeCount)
    print("Found cancellation: " .. tostring(foundCancellation))

    -- Assertions
    assert(world.enemies[1].hp == 3, "Enemy should have 3 HP remaining")
    assert(not foundCancellation, "Should NOT find cancellation message")
    assert(strikeCount == 2, "Should have 2 strikes dealing damage")

    print("\n✓ Test passed!")
end

-- Run tests
testStrikeWithDoubleTapKillsEnemy()
testStrikeWithDoubleTapBothHit()

print("\n=== ALL TESTS PASSED ===")
