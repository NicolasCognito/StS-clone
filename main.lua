-- MAIN GAME LOOP
-- Demonstrates MapEngine + CombatEngine working together

local World = require("World")
local MapEngine = require("MapEngine")
local CombatEngine = require("CombatEngine")
local MapCLI = require("MapCLI")
local CombatCLI = require("CombatCLI")
local StartCombat = require("Pipelines.StartCombat")
local EndCombat = require("Pipelines.EndCombat")

local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local Relics = require("Data.relics")
local Maps = require("Data.maps")
local Utils = require("utils")

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
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

local function checkVictory(world)
    local playerAlive = world.player.hp > 0
    local enemiesDefeated = true

    for _, enemy in ipairs(world.enemies or {}) do
        if enemy.hp > 0 then
            enemiesDefeated = false
            break
        end
    end

    return playerAlive and enemiesDefeated
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
-- MAIN GAME DEMO
-- ============================================================================

print("=== SLAY THE SPIRE CLONE ===")
print("Welcome, " .. world.player.name .. "!")
print()

-- PHASE 1: Map Navigation using MapEngine + MapCLI
print("=== MAP PHASE ===")
print("Navigate the map and choose your path...")
print()

MapCLI.play(world)

-- PHASE 2: Combat Demo using CombatEngine + CombatCLI
print()
print("=== COMBAT PHASE ===")
print("Preparing for battle...")
print()

-- Setup combat encounter
world.enemies = {
    copyEnemy(Enemies.Goblin),
    copyEnemy(Enemies.Goblin)
}

-- Initialize combat state via StartCombat pipeline
StartCombat.execute(world)

-- Run combat using CombatEngine through CombatCLI
CombatCLI.play(world)

-- Determine combat result
local victory = checkVictory(world)

-- Clean up combat state via EndCombat pipeline
EndCombat.execute(world, victory)

-- ============================================================================
-- POST-GAME SUMMARY
-- ============================================================================

print()
print("=== GAME SUMMARY ===")
print("Result: " .. (victory and "VICTORY!" or "DEFEAT"))
print("Player HP: " .. world.player.currentHp .. "/" .. world.player.maxHp)
print("Gold: " .. world.player.gold)
print()

if victory then
    print("You survived the encounter and can continue your journey!")
else
    print("Your journey ends here...")
end
