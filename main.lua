-- MAIN ENTRY POINT
-- Sets up world state and runs a simple combat encounter

local World = require("World")
local CombatEngine = require("CombatEngine")
local StartCombat = require("Pipelines.StartCombat")
local EndCombat = require("Pipelines.EndCombat")
local Cards = require("Data.Cards.Cards")
local Enemies = require("Data.Enemies.Enemies")
local Relics = require("Data.Relics.Relics")

-- Helper function to copy a card template (for deck building)
local function copyCard(cardTemplate)
    local copy = {}
    for k, v in pairs(cardTemplate) do
        copy[k] = v
    end
    return copy
end

-- Helper function to copy an enemy template
local function copyEnemy(enemyTemplate)
    local copy = {}
    for k, v in pairs(enemyTemplate) do
        copy[k] = v
    end
    return copy
end

-- Build a starting deck (5 Strikes, 4 Defends, 1 Bash + test cards)
-- Returns an array of card templates (no state property)
local function buildStartingDeck()
    local cards = {}

    -- Add 5 Strikes
    for i = 1, 5 do
        table.insert(cards, copyCard(Cards.Strike))
    end

    -- Add 4 Defends
    for i = 1, 4 do
        table.insert(cards, copyCard(Cards.Defend))
    end

    -- Add 1 Bash
    table.insert(cards, copyCard(Cards.Bash))

    -- Add 1 Flame Barrier (for testing Thorns)
    table.insert(cards, copyCard(Cards.FlameBarrier))

    -- Add 1 Bloodletting (for testing HP loss with ignoreBlock)
    table.insert(cards, copyCard(Cards.Bloodletting))

    -- Add 1 Blood for Blood (for testing dynamic cost reduction)
    table.insert(cards, copyCard(Cards.BloodForBlood))

    -- Add 1 Infernal Blade (for testing costsZeroThisTurn)
    table.insert(cards, copyCard(Cards.InfernalBlade))

    -- Add 1 Corruption (for testing powers)
    table.insert(cards, copyCard(Cards.Corruption))

    return cards
end

-- ============================================================================
-- CREATE WORLD STATE
-- ============================================================================

local world = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = buildStartingDeck(),  -- Cards go directly in world.player.cards
    relics = {Relics.PaperPhrog},  -- Change to Relics.SneckoEye to test Confused
    gold = 99
})

-- ============================================================================
-- START COMBAT ENCOUNTER
-- ============================================================================

print("=== SLAY THE SPIRE CLONE ===")
print("Welcome to combat!")
print("\nCommands:")
print("  play <number> - Play a card from your hand")
print("  end - End your turn")
print("\nPress Enter to start...")
io.read()

-- Set up enemies for this encounter (two goblins)
world.enemies = {
    copyEnemy(Enemies.Goblin),
    copyEnemy(Enemies.Goblin)
}

-- Start combat (initializes context, applies relic effects, draws initial hand)
StartCombat.execute(world)

-- Run the combat loop
CombatEngine.playGame(world)

-- End combat (cleanup, apply results, handle rewards)
local victory = world.player.hp > 0
EndCombat.execute(world, victory)

-- Display final world state
print("\n=== AFTER COMBAT ===")
print("Player HP: " .. world.player.currentHp .. "/" .. world.player.maxHp)
print("Gold: " .. world.player.gold)
