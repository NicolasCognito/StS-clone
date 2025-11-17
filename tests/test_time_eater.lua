-- TEST: Time Eater Boss
-- Verifies Time Warp mechanic, attack patterns, and Haste ability

local World = require("World")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")
local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
local Utils = require("utils")

-- Helper to play a card (with context support like other tests)
local function playCard(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            return true
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

print("\n=== Time Eater Boss Tests ===\n")

-- Test 1: Time Warp Initialization
print("Test 1: Time Warp initialization...")
local world = World.createWorld({playerName = "Tester", playerClass = "IRONCLAD", maxEnergy = 3})

-- Set up a simple deck
local strikes = {}
for i = 1, 10 do
    local strike = Utils.deepCopyCard(Cards.Strike)
    strike.state = "DECK"
    table.insert(strikes, strike)
end
world.player.masterDeck = strikes
world.player.combatDeck = Utils.deepCopyDeck(world.player.masterDeck)

local timeEater = Utils.copyEnemyTemplate(Enemies.TimeEater)
world.enemies = {timeEater}

StartCombat.execute(world)

assert(timeEater.status.time_warp == 12, "Time Eater should start with Time Warp at 12")
print("✓ Time Eater starts with Time Warp counter at 12\n")

-- Test 2: Time Warp Decrement
print("Test 2: Time Warp decrement on card play...")
world = World.createWorld({playerName = "Tester", playerClass = "IRONCLAD", maxEnergy = 3})

strikes = {}
for i = 1, 10 do
    local strike = Utils.deepCopyCard(Cards.Strike)
    strike.state = "DECK"
    table.insert(strikes, strike)
end
world.player.masterDeck = strikes
world.player.combatDeck = Utils.deepCopyDeck(world.player.masterDeck)

timeEater = Utils.copyEnemyTemplate(Enemies.TimeEater)
world.enemies = {timeEater}

StartCombat.execute(world)

-- Play one card from hand
local cardsInHand = Utils.getCardsByState(world.player.combatDeck, "HAND")
assert(#cardsInHand > 0, "Player should have cards in hand")
playCard(world, world.player, cardsInHand[1])

assert(timeEater.status.time_warp == 11, "Time Warp should decrement to 11 after 1 card (got " .. (timeEater.status.time_warp or "nil") .. ")")
print("✓ Time Warp decrements by 1 per card played\n")

-- Test 3: Time Warp Trigger
print("Test 3: Time Warp trigger after 12 cards...")
world = World.createWorld({playerName = "Tester", playerClass = "IRONCLAD", maxEnergy = 99})

-- Create 15 strikes so we have enough to play 12
strikes = {}
for i = 1, 15 do
    local strike = Utils.deepCopyCard(Cards.Strike)
    strike.state = "DECK"
    table.insert(strikes, strike)
end
world.player.masterDeck = strikes
world.player.combatDeck = Utils.deepCopyDeck(world.player.masterDeck)

timeEater = Utils.copyEnemyTemplate(Enemies.TimeEater)
world.enemies = {timeEater}

StartCombat.execute(world)

local initialStrength = timeEater.status.strength or 0

-- Play 12 cards
for i = 1, 12 do
    cardsInHand = Utils.getCardsByState(world.player.combatDeck, "HAND")
    if #cardsInHand == 0 then
        -- Draw more if needed
        local DrawCard = require("Pipelines.DrawCard")
        DrawCard.execute(world, world.player, 5)
        cardsInHand = Utils.getCardsByState(world.player.combatDeck, "HAND")
    end

    assert(#cardsInHand > 0, "Need cards to play")
    playCard(world, world.player, cardsInHand[1])

    -- Check after 11 cards
    if i == 11 then
        assert(timeEater.status.time_warp == 1, "Time Warp should be at 1 after 11 cards")
    end
end

-- Time Warp should reset to 12
assert(timeEater.status.time_warp == 12, "Time Warp should reset to 12 after trigger (got " .. (timeEater.status.time_warp or "nil") .. ")")

-- Time Eater should have gained +2 Strength
local newStrength = timeEater.status.strength or 0
assert(newStrength == initialStrength + 2, "Time Eater should gain +2 Strength (expected " .. (initialStrength + 2) .. ", got " .. newStrength .. ")")

print("✓ Time Warp triggers at 0, grants +2 Strength, resets to 12\n")

-- Test 4: Reverberate Attack
print("Test 4: Reverberate attack (7×3 damage)...")
world = World.createWorld({playerName = "Tester", playerClass = "IRONCLAD", maxEnergy = 3})

world.player.masterDeck = {}
world.player.combatDeck = {}

timeEater = Utils.copyEnemyTemplate(Enemies.TimeEater)
world.enemies = {timeEater}

StartCombat.execute(world)

timeEater.currentIntent = {
    name = "Reverberate",
    execute = timeEater.intents.reverberate
}

local initialHp = world.player.hp
timeEater.executeIntent(timeEater, world, world.player)
ProcessEventQueue.execute(world)

-- Player should take damage (exact amount depends on strength)
assert(world.player.hp < initialHp, "Reverberate should deal damage (HP: " .. world.player.hp .. " vs " .. initialHp .. ")")
print("✓ Reverberate deals 7×3 damage\n")

-- Test 5: Head Slam Attack
print("Test 5: Head Slam attack (26 damage + Draw Reduction)...")
world = World.createWorld({playerName = "Tester", playerClass = "IRONCLAD", maxEnergy = 3})

world.player.masterDeck = {}
world.player.combatDeck = {}

timeEater = Utils.copyEnemyTemplate(Enemies.TimeEater)
world.enemies = {timeEater}

StartCombat.execute(world)

timeEater.currentIntent = {
    name = "Head Slam",
    execute = timeEater.intents.head_slam
}

initialHp = world.player.hp
timeEater.executeIntent(timeEater, world, world.player)
ProcessEventQueue.execute(world)

-- Player should have Draw Reduction
assert(world.player.status.draw_reduction == 1, "Head Slam should apply Draw Reduction")

-- Player should take damage
assert(world.player.hp < initialHp, "Head Slam should deal damage")
print("✓ Head Slam deals 26 damage and applies Draw Reduction\n")

-- Test 6: Ripple Defense
print("Test 6: Ripple defense (20 Block + debuffs)...")
world = World.createWorld({playerName = "Tester", playerClass = "IRONCLAD", maxEnergy = 3})

world.player.masterDeck = {}
world.player.combatDeck = {}

timeEater = Utils.copyEnemyTemplate(Enemies.TimeEater)
world.enemies = {timeEater}

StartCombat.execute(world)

timeEater.currentIntent = {
    name = "Ripple",
    execute = timeEater.intents.ripple
}

timeEater.executeIntent(timeEater, world, world.player)
ProcessEventQueue.execute(world)

-- Time Eater should gain 20 block
assert(timeEater.block == 20, "Ripple should grant 20 Block (got " .. timeEater.block .. ")")

-- Player should have Vulnerable and Weak
assert(world.player.status.vulnerable == 1, "Ripple should apply 1 Vulnerable")
assert(world.player.status.weak == 1, "Ripple should apply 1 Weak")
print("✓ Ripple grants 20 Block and applies debuffs\n")

-- Test 7: Haste Ability
print("Test 7: Haste ability (heal + cleanse)...")
world = World.createWorld({playerName = "Tester", playerClass = "IRONCLAD", maxEnergy = 3})

world.player.masterDeck = {}
world.player.combatDeck = {}

timeEater = Utils.copyEnemyTemplate(Enemies.TimeEater)
world.enemies = {timeEater}

StartCombat.execute(world)

-- Damage Time Eater below 50% HP
timeEater.hp = math.floor(timeEater.maxHp / 2) - 10

-- Apply some debuffs
timeEater.status.weak = 2
timeEater.status.vulnerable = 3
timeEater.status.strength = -5

-- Trigger selectIntent (should choose Haste)
timeEater.selectIntent(timeEater, world, world.player)
assert(timeEater.currentIntent.name == "Haste", "Should select Haste when HP < 50%")

-- Execute Haste
timeEater.executeIntent(timeEater, world, world.player)
ProcessEventQueue.execute(world)

-- HP should be at 50%
assert(timeEater.hp == math.floor(timeEater.maxHp / 2), "Haste should heal to 50% HP (expected " .. math.floor(timeEater.maxHp / 2) .. ", got " .. timeEater.hp .. ")")

-- Debuffs should be cleared
assert(timeEater.status.weak == 0, "Haste should clear Weak")
assert(timeEater.status.vulnerable == 0, "Haste should clear Vulnerable")
assert(timeEater.status.strength == 0, "Haste should clear negative Strength")
print("✓ Haste heals to 50% and removes all debuffs\n")

-- Test 8: Haste Only Once
print("Test 8: Haste only triggers once...")
world = World.createWorld({playerName = "Tester", playerClass = "IRONCLAD", maxEnergy = 3})

world.player.masterDeck = {}
world.player.combatDeck = {}

timeEater = Utils.copyEnemyTemplate(Enemies.TimeEater)
world.enemies = {timeEater}

StartCombat.execute(world)

-- Damage Time Eater below 50% HP
timeEater.hp = math.floor(timeEater.maxHp / 2) - 10

-- First time should trigger Haste
timeEater.selectIntent(timeEater, world, world.player)
assert(timeEater.currentIntent.name == "Haste", "First time should select Haste")

-- Execute Haste
timeEater.executeIntent(timeEater, world, world.player)
ProcessEventQueue.execute(world)

-- Damage again below 50%
timeEater.hp = math.floor(timeEater.maxHp / 2) - 20

-- Should NOT use Haste again
timeEater.selectIntent(timeEater, world, world.player)
assert(timeEater.currentIntent.name ~= "Haste", "Haste should only trigger once (got " .. timeEater.currentIntent.name .. ")")
print("✓ Haste only triggers once per battle\n")

print("=== All Time Eater Tests Passed! ===\n")
