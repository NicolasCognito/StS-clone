-- MAIN ENTRY POINT
-- Sets up and runs a simple combat encounter

local Engine = require("Engine")
local Cards = require("Data.Cards.Cards")
local Enemies = require("Data.Enemies.Enemies")

-- Helper function to copy a card (for deck building)
local function copyCard(cardTemplate)
    local copy = {}
    for k, v in pairs(cardTemplate) do
        copy[k] = v
    end
    return copy
end

-- Build a starting deck (5 Strikes, 4 Defends, 1 Bash)
local function buildStartingDeck()
    local deck = {}

    -- Add 5 Strikes
    for i = 1, 5 do
        table.insert(deck, copyCard(Cards.Strike))
    end

    -- Add 4 Defends
    for i = 1, 4 do
        table.insert(deck, copyCard(Cards.Defend))
    end

    -- Add 1 Bash
    table.insert(deck, copyCard(Cards.Bash))

    return deck
end

-- Initialize player data
local playerData = {
    id = "IronClad",
    hp = 80,
    relics = {}
}

-- Initialize enemy (copy the Goblin template)
local enemyData = copyCard(Enemies.Goblin)

-- Create game state
local world = Engine.createGameState(playerData, enemyData)

-- Set up player's deck
world.player.deck = buildStartingDeck()

-- Start the game
print("=== SLAY THE SPIRE CLONE ===")
print("Welcome to combat!")
print("\nCommands:")
print("  play <number> - Play a card from your hand")
print("  end - End your turn")
print("\nPress Enter to start...")
io.read()

Engine.playGame(world)
