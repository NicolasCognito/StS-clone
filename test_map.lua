-- TEST MAP NAVIGATION
-- Simple test to demonstrate map navigation and Winged Boots

local World = require("World")
local MapEngine = require("MapEngine")
local ChooseNextNode = require("Pipelines.ChooseNextNode")
local Maps = require("Data.Maps.Maps")
local Cards = require("Data.Cards.Cards")
local Relics = require("Data.Relics.Relics")

-- Helper function to copy a card template
local function copyCard(cardTemplate)
    local copy = {}
    for k, v in pairs(cardTemplate) do
        copy[k] = v
    end
    return copy
end

-- Build a simple starting deck
local function buildStartingDeck()
    local cards = {}
    for i = 1, 5 do
        table.insert(cards, copyCard(Cards.Strike))
    end
    for i = 1, 4 do
        table.insert(cards, copyCard(Cards.Defend))
    end
    table.insert(cards, copyCard(Cards.Bash))
    return cards
end

print("=== MAP NAVIGATION TEST ===\n")

-- Test 1: Normal navigation (following paths)
print("--- Test 1: Normal Path Navigation ---")
local world1 = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = buildStartingDeck(),
    relics = {},
    gold = 50,
    map = Maps.TestMap,
    startNode = Maps.TestMap.startNode
})

print("Starting at: " .. world1.currentNode)
ChooseNextNode.execute(world1, "floor2-1")  -- Valid connection to floor 2
print()

-- Test 2: Invalid navigation (not connected)
print("--- Test 2: Invalid Path (Not Connected) ---")
local world2 = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = buildStartingDeck(),
    relics = {},
    gold = 50,
    map = Maps.TestMap,
    startNode = Maps.TestMap.startNode
})

ChooseNextNode.execute(world2, "floor3-1")  -- Not connected - should fail
print()

-- Test 3: Winged Boots - valid use (next floor)
print("--- Test 3: Winged Boots - Valid Use (Next Floor) ---")
local world3 = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = buildStartingDeck(),
    relics = {Relics.WingedBoots},
    gold = 50,
    map = Maps.TestMap,
    startNode = Maps.TestMap.startNode
})
world3.wingedBootsCharges = 3  -- Set charges when player has Winged Boots

print("Starting at: " .. world3.currentNode)
print("Winged Boots charges: " .. world3.wingedBootsCharges)
ChooseNextNode.execute(world3, "floor2-2")  -- Skip to floor 2 rest site with Winged Boots
print()

-- Test 4: Winged Boots - invalid use (skip floor)
print("--- Test 4: Winged Boots - Invalid Use (Skip Floor) ---")
local world4 = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = buildStartingDeck(),
    relics = {Relics.WingedBoots},
    gold = 50,
    map = Maps.TestMap,
    startNode = Maps.TestMap.startNode
})
world4.wingedBootsCharges = 3

print("Starting at: " .. world4.currentNode)
ChooseNextNode.execute(world4, "floor3-1")  -- Try to skip floor - should fail
print()

-- Test 5: Winged Boots - charges depleted
print("--- Test 5: Winged Boots - Charge Depletion ---")
local world5 = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = buildStartingDeck(),
    relics = {Relics.WingedBoots},
    gold = 50,
    map = Maps.TestMap,
    startNode = Maps.TestMap.startNode
})
world5.wingedBootsCharges = 3

print("Starting at: " .. world5.currentNode)
ChooseNextNode.execute(world5, "floor2-2")  -- Use Winged Boots (charge 3 -> 2)
print("Current node: " .. world5.currentNode)
ChooseNextNode.execute(world5, "floor3-2")  -- Use Winged Boots (charge 2 -> 1)
print()

print("=== ALL TESTS COMPLETE ===")
