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

-- Helper function to copy a relic
local function copyRelic(relicTemplate)
    local copy = {}
    for k, v in pairs(relicTemplate) do
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
ChooseNextNode.execute(world1, "floor1-2")  -- Valid connection
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

ChooseNextNode.execute(world2, "floor2-1")  -- Not connected - should fail
print()

-- Test 3: Winged Boots - valid use (next floor)
print("--- Test 3: Winged Boots - Valid Use (Next Floor) ---")
local wingedBoots = copyRelic(Relics.WingedBoots)
local world3 = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = buildStartingDeck(),
    relics = {wingedBoots},
    gold = 50,
    map = Maps.TestMap,
    startNode = Maps.TestMap.startNode
})

print("Starting at: " .. world3.currentNode)
print("Winged Boots charges: " .. wingedBoots.charges)
ChooseNextNode.execute(world3, "floor2-1")  -- Skip to floor 2 with Winged Boots
print()

-- Test 4: Winged Boots - invalid use (same floor)
print("--- Test 4: Winged Boots - Invalid Use (Same Floor) ---")
local wingedBoots2 = copyRelic(Relics.WingedBoots)
local world4 = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = buildStartingDeck(),
    relics = {wingedBoots2},
    gold = 50,
    map = Maps.TestMap,
    startNode = Maps.TestMap.startNode
})

print("Starting at: " .. world4.currentNode)
ChooseNextNode.execute(world4, "floor1-3")  -- Try to use Winged Boots on same floor - should fail
print()

-- Test 5: Winged Boots - charges depleted
print("--- Test 5: Winged Boots - Charge Depletion ---")
local wingedBoots3 = copyRelic(Relics.WingedBoots)
local world5 = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = buildStartingDeck(),
    relics = {wingedBoots3},
    gold = 50,
    map = Maps.TestMap,
    startNode = Maps.TestMap.startNode
})

print("Starting at: " .. world5.currentNode)
ChooseNextNode.execute(world5, "floor2-2")  -- Use Winged Boots (charge 3 -> 2)
print("Current node: " .. world5.currentNode)
ChooseNextNode.execute(world5, "floor3-1")  -- Use Winged Boots (charge 2 -> 1)
print()

print("=== ALL TESTS COMPLETE ===")
