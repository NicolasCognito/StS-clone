-- MAIN ENTRY POINT
-- Sets up and runs a simple combat encounter

local Engine = require("Engine")
local Cards = require("Data.Cards.Cards")
local Enemies = require("Data.Enemies.Enemies")
local Relics = require("Data.Relics.Relics")

-- Helper function to copy a card (for deck building)
local function copyCard(cardTemplate)
    local copy = {}
    for k, v in pairs(cardTemplate) do
        copy[k] = v
    end
    -- Initialize state to DECK
    copy.state = "DECK"
    return copy
end

-- Build a starting deck (5 Strikes, 4 Defends, 1 Bash)
-- Returns an array of cards with state = "DECK"
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

-- Initialize player data
local playerData = {
    id = "IronClad",
    hp = 80,
    relics = {Relics.PaperPhrog}  -- Change to Relics.SneckoEye to test Confused
}

-- Initialize enemy (copy the Goblin template)
local enemyData = copyCard(Enemies.Goblin)

-- Create game state
local world = Engine.createGameState(playerData, enemyData)

-- Set up player's cards (all start in DECK state)
world.player.cards = buildStartingDeck()

-- Apply relic combat-start effects
-- Check if player has Snecko Eye and apply Confused
for _, relic in ipairs(world.player.relics) do
    if relic.id == "Snecko_Eye" then
        -- Initialize status table if needed
        if not world.player.status then
            world.player.status = {}
        end
        -- Apply permanent Confused for the combat
        world.player.status.confused = 999  -- Lasts entire combat
        table.insert(world.log, "You are Confused!")
    end
end

-- Start the game
print("=== SLAY THE SPIRE CLONE ===")
print("Welcome to combat!")
print("\nCommands:")
print("  play <number> - Play a card from your hand")
print("  end - End your turn")
print("\nPress Enter to start...")
io.read()

Engine.playGame(world)
