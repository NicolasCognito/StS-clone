-- Sets up world state and runs an expanded combat encounter

local World = require("World")
local CombatEngine = require("CombatEngine")
local StartCombat = require("Pipelines.StartCombat")
local EndCombat = require("Pipelines.EndCombat")

local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local Relics = require("Data.relics")
local Maps = require("Data.maps")
local Utils = require("utils")

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

local function buildStartingDeck()
    local cards = {}

    for _ = 1, 5 do
        table.insert(cards, copyCard(Cards.Strike))
    end
    for _ = 1, 4 do
        table.insert(cards, copyCard(Cards.Defend))
    end

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

-- Setup a simple multi-enemy encounter
world.enemies = {
    copyEnemy(Enemies.Goblin),
    copyEnemy(Enemies.Goblin)
}

print("=== SLAY THE SPIRE CLONE ===")
print("Welcome to combat!")
print("\nCommands:")
print("  play <number> - Play a card from your hand")
print("  end - End your turn")
print("\nPress Enter to start...")
io.read()

StartCombat.execute(world)
CombatEngine.playGame(world)

local playerAlive = world.player.hp > 0
local enemiesDefeated = true
for _, enemy in ipairs(world.enemies or {}) do
    if enemy.hp > 0 then
        enemiesDefeated = false
        break
    end
end
local victory = playerAlive and enemiesDefeated

EndCombat.execute(world, victory)

print("\n=== AFTER COMBAT ===")
print("Player HP: " .. world.player.currentHp .. "/" .. world.player.maxHp)
print("Gold: " .. world.player.gold)
