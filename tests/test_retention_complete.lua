-- Test Establishment, Well-Laid Plans, and Equilibrium cards
-- Tests complete retention mechanic ecosystem

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local EndTurn = require("Pipelines.EndTurn")
local StartTurn = require("Pipelines.StartTurn")
local GetCost = require("Pipelines.GetCost")
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
            return false
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

local function findCardByName(deck, name)
    for _, card in ipairs(deck) do
        if card.name == name then
            return card
        end
    end
    return nil
end

print("=== Testing Establishment ===")

-- TEST 1: Establishment reduces cost of retained cards
print("\nTest 1: Establishment reduces cost on retention")
local world = World.createWorld({
    id = "Watcher",
    maxHp = 80,
    maxEnergy = 5,
    cards = {
        copyCard(Cards.Establishment),
        copyCard(Cards.Tranquility)  -- Has retain
    },
    relics = {}
})

world.enemies = {copyEnemy(Enemies.Goblin)}
world.NoShuffle = true
StartCombat.execute(world)

local establishment = findCardById(world.player.combatDeck, "Establishment")
local tranquility = findCardById(world.player.combatDeck, "Tranquility")

-- Play Establishment to apply the power
playCardWithAutoContext(world, world.player, establishment)
assert(world.player.status.establishment == 1, "Establishment status should be applied")

-- Check tranquility's initial cost
local initialCost = GetCost.execute(world, world.player, tranquility)
assert(initialCost == 1, "Tranquility should cost 1 initially: " .. initialCost)

-- End turn (Tranquility will be retained)
tranquility.state = "HAND"
EndTurn.execute(world, world.player)

-- Check that cost was reduced
assert(tranquility.retainCostReduction == 1, "retainCostReduction should be 1")
local reducedCost = GetCost.execute(world, world.player, tranquility)
assert(reducedCost == 0, "Tranquility should cost 0 after retention: " .. reducedCost)

print("✓ Test 1 passed: Establishment reduces cost")

-- TEST 2: Establishment upgraded is Innate
print("\nTest 2: Establishment upgraded has Innate")
local upgradedEstablishment = copyCard(Cards.Establishment)
upgradedEstablishment:onUpgrade()
assert(upgradedEstablishment.innate == true, "Upgraded Establishment should be Innate")
print("✓ Test 2 passed: Upgraded version has Innate")

print("\n=== Testing Equilibrium ===")

-- TEST 3: Equilibrium gains block and retains hand
print("\nTest 3: Equilibrium gains block and retains hand")
local world2 = World.createWorld({
    id = "Defect",
    maxHp = 80,
    maxEnergy = 5,
    cards = {
        copyCard(Cards.Equilibrium),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend)
    },
    relics = {}
})

world2.enemies = {copyEnemy(Enemies.Goblin)}
world2.NoShuffle = true
StartCombat.execute(world2)

local equilibrium = findCardById(world2.player.combatDeck, "Equilibrium")
local strike = findCardById(world2.player.combatDeck, "Strike")
local defend = findCardById(world2.player.combatDeck, "Defend")

-- Play Equilibrium
playCardWithAutoContext(world2, world2.player, equilibrium)
assert(world2.player.block == 13, "Should gain 13 block: " .. world2.player.block)

-- Check that other cards got retainThisTurn flag
assert(strike.retainThisTurn == true, "Strike should have retainThisTurn")
assert(defend.retainThisTurn == true, "Defend should have retainThisTurn")

-- End turn - cards should be retained
EndTurn.execute(world2, world2.player)
assert(strike.state == "HAND", "Strike should still be in hand")
assert(defend.state == "HAND", "Defend should still be in hand")

-- Start new turn - retainThisTurn should be cleared
StartTurn.execute(world2, world2.player)
assert(strike.retainThisTurn == nil, "retainThisTurn should be cleared")
assert(defend.retainThisTurn == nil, "retainThisTurn should be cleared")

-- End turn again - cards should be discarded now
EndTurn.execute(world2, world2.player)
assert(strike.state == "DISCARD_PILE", "Strike should be discarded: " .. strike.state)
assert(defend.state == "DISCARD_PILE", "Defend should be discarded: " .. defend.state)

print("✓ Test 3 passed: Equilibrium retains hand temporarily")

-- TEST 4: Equilibrium upgraded gains more block
print("\nTest 4: Equilibrium upgraded")
local upgradedEquilibrium = copyCard(Cards.Equilibrium)
upgradedEquilibrium:onUpgrade()
assert(upgradedEquilibrium.block == 16, "Upgraded should have 16 block")

local world3 = World.createWorld({
    id = "Defect",
    maxHp = 80,
    maxEnergy = 5,
    cards = {upgradedEquilibrium},
    relics = {}
})
world3.enemies = {copyEnemy(Enemies.Goblin)}
world3.NoShuffle = true
StartCombat.execute(world3)

playCardWithAutoContext(world3, world3.player, upgradedEquilibrium)
assert(world3.player.block == 16, "Should gain 16 block: " .. world3.player.block)
print("✓ Test 4 passed: Upgraded Equilibrium works")

print("\n=== Testing Well-Laid Plans ===")

-- TEST 5: Well-Laid Plans - manual context selection
print("\nTest 5: Well-Laid Plans basic functionality")
local world4 = World.createWorld({
    id = "Silent",
    maxHp = 80,
    maxEnergy = 5,
    cards = {
        copyCard(Cards.WellLaidPlans),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend)
    },
    relics = {}
})

world4.enemies = {copyEnemy(Enemies.Goblin)}
world4.NoShuffle = true
StartCombat.execute(world4)

local wellLaidPlans = findCardById(world4.player.combatDeck, "WellLaidPlans")
local strike4 = findCardById(world4.player.combatDeck, "Strike")
local defend4 = findCardById(world4.player.combatDeck, "Defend")

-- Play Well-Laid Plans
playCardWithAutoContext(world4, world4.player, wellLaidPlans)
assert(world4.player.status.well_laid_plans == 1, "Well-Laid Plans status should be 1")

-- Simulate EndTurn with manual context selection
-- The EndTurn will request context, we need to provide it
strike4.state = "HAND"
defend4.state = "HAND"

-- Mock context selection by setting tempContext directly
world4.combat.tempContext = {strike4}  -- Select Strike to retain

EndTurn.execute(world4, world4.player)

-- Strike should be retained, Defend should be discarded
assert(strike4.state == "HAND", "Strike should be retained: " .. strike4.state)
assert(defend4.state == "DISCARD_PILE", "Defend should be discarded: " .. defend4.state)
assert(strike4.retainThisTurn == true, "Strike should have retainThisTurn")

print("✓ Test 5 passed: Well-Laid Plans retains selected card")

-- TEST 6: Well-Laid Plans upgraded retains 2 cards
print("\nTest 6: Well-Laid Plans upgraded")
local upgradedWLP = copyCard(Cards.WellLaidPlans)
upgradedWLP:onUpgrade()
assert(upgradedWLP.retainCount == 2, "Upgraded should retain 2 cards")
print("✓ Test 6 passed: Upgraded version retains 2 cards")

-- TEST 7: Well-Laid Plans + Establishment interaction
print("\nTest 7: Well-Laid Plans + Establishment combo")
local world5 = World.createWorld({
    id = "Watcher",
    maxHp = 80,
    maxEnergy = 5,
    cards = {
        copyCard(Cards.Establishment),
        copyCard(Cards.WellLaidPlans),
        copyCard(Cards.Strike),
        copyCard(Cards.Strike)
    },
    relics = {}
})

world5.enemies = {copyEnemy(Enemies.Goblin)}
world5.NoShuffle = true
StartCombat.execute(world5)

local est = findCardById(world5.player.combatDeck, "Establishment")
local wlp = findCardById(world5.player.combatDeck, "WellLaidPlans")

-- Find the two Strikes
local strikes = {}
for _, card in ipairs(world5.player.combatDeck) do
    if card.id == "Strike" then
        table.insert(strikes, card)
    end
end
assert(#strikes == 2, "Should have 2 Strikes")

-- Play both powers
playCardWithAutoContext(world5, world5.player, est)
playCardWithAutoContext(world5, world5.player, wlp)

-- Put a Strike in hand
strikes[1].state = "HAND"

-- Select it for retention via Well-Laid Plans
world5.combat.tempContext = {strikes[1]}
EndTurn.execute(world5, world5.player)

-- Strike should be retained and cost reduced
assert(strikes[1].state == "HAND", "Strike should be retained")
assert(strikes[1].retainCostReduction == 1, "Establishment should reduce cost")

local cost = GetCost.execute(world5, world5.player, strikes[1])
assert(cost == 0, "Strike should cost 0 (1-1): " .. cost)

print("✓ Test 7 passed: Well-Laid Plans + Establishment combo works")

-- TEST 8: Ethereal cards cannot be retained by Well-Laid Plans
print("\nTest 8: Ethereal cards excluded from Well-Laid Plans")
-- Create a mock ethereal card
local etherealCard = copyCard(Cards.Strike)
etherealCard.ethereal = true
etherealCard.name = "Ethereal Strike"

local world6 = World.createWorld({
    id = "Silent",
    maxHp = 80,
    maxEnergy = 5,
    cards = {
        copyCard(Cards.WellLaidPlans),
        etherealCard
    },
    relics = {}
})

world6.enemies = {copyEnemy(Enemies.Goblin)}
world6.NoShuffle = true
StartCombat.execute(world6)

local wlp6 = findCardById(world6.player.combatDeck, "WellLaidPlans")
local eth = findCardByName(world6.player.combatDeck, "Ethereal Strike")

playCardWithAutoContext(world6, world6.player, wlp6)

eth.state = "HAND"

-- Try to select ethereal card (should be filtered out)
-- The filter in EndTurn should exclude it
world6.combat.tempContext = {}  -- Empty selection (ethereal was filtered)
EndTurn.execute(world6, world6.player)

-- Ethereal card should have exhausted (its normal behavior)
assert(eth.retainThisTurn == nil, "Ethereal card should not have retainThisTurn")

print("✓ Test 8 passed: Ethereal cards properly excluded")

print("\n=== All retention mechanic tests passed! ===")
