-- MAIN GAME LOOP
-- Demonstrates integrated MapEngine + CombatEngine flow
-- Combat encounters are triggered automatically through map events

local World = require("World")
local MapCLI = require("UIs.CLI.MapCLI")

local Cards = require("Data.cards")
local Relics = require("Data.relics")
local Maps = require("Data.maps")
local Utils = require("utils")

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function buildStartingDeck()
    local cards = {}

    -- Starting cards
    for _ = 1, 5 do
        table.insert(cards, copyCard(Cards.Strike))
    end
    for _ = 1, 4 do
        table.insert(cards, copyCard(Cards.Defend))
    end

    -- Additional test cards
    table.insert(cards, copyCard(Cards.Bash))
    table.insert(cards, copyCard(Cards.FlameBarrier))
    table.insert(cards, copyCard(Cards.Bloodletting))
    table.insert(cards, copyCard(Cards.BloodForBlood))
    table.insert(cards, copyCard(Cards.InfernalBlade))
    table.insert(cards, copyCard(Cards.Corruption))
    table.insert(cards, copyCard(Cards.Discovery))
    table.insert(cards, copyCard(Cards.GrandFinale))
    table.insert(cards, copyCard(Cards.Whirlwind))
    table.insert(cards, copyCard(Cards.Skewer))
    table.insert(cards, copyCard(Cards.Intimidate))
    table.insert(cards, copyCard(Cards.Thunderclap))
    table.insert(cards, copyCard(Cards.DaggerThrow))
    table.insert(cards, copyCard(Cards.Headbutt))

    return cards
end

-- ============================================================================
-- WORLD SETUP
-- ============================================================================

local testMap = Maps.TestMap
local world = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = buildStartingDeck(),
    relics = {Relics.PaperPhrog, Relics.ChemicalX},
    gold = 99,
    map = testMap,
    startNode = testMap and testMap.startNode or nil
})

-- ============================================================================
-- MAIN GAME LOOP
-- ============================================================================

print("=== SLAY THE SPIRE CLONE ===")
print("Welcome, " .. world.player.name .. "!")
print("Navigate the map and fight enemies to progress.")
print("Combat encounters will start automatically at combat nodes.")
print()

-- Run the integrated map + combat loop
-- MapCLI handles both map navigation and combat encounters seamlessly
MapCLI.play(world)

-- ============================================================================
-- POST-GAME SUMMARY
-- ============================================================================

print()
print("=== GAME OVER ===")
print("Final Stats:")
print("  Player HP: " .. world.player.currentHp .. "/" .. world.player.maxHp)
print("  Gold: " .. world.player.gold)
print("  Floor Reached: " .. (world.floor or 1))
print()

if world.player.currentHp > 0 then
    print("You survived and continue your journey!")
else
    print("Your journey ends here...")
end
