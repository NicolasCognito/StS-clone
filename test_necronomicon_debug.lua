local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local StartTurn = require("Pipelines.StartTurn")
local ContextProvider = require("Pipelines.ContextProvider")

math.randomseed(1337)

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

local function findCardById(deck, cardId)
    for _, card in ipairs(deck) do
        if card.id == cardId then
            return card
        end
    end
    error("Card " .. cardId .. " not found in deck")
end

local function playCardWithAutoContext(world, player, card)
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

print("=== DEBUG: Necronomicon Test ===")

-- Check if HeavyBlade exists
print("Cards.HeavyBlade: " .. tostring(Cards.HeavyBlade))
if Cards.HeavyBlade then
    print("  id: " .. Cards.HeavyBlade.id)
    print("  cost: " .. Cards.HeavyBlade.cost)
    print("  type: " .. Cards.HeavyBlade.type)
end

local deck = {
    copyCard(Cards.HeavyBlade),
    copyCard(Cards.Strike),
    copyCard(Cards.Defend)
}

local world = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = deck,
    relics = {
        {id = "Necronomicon", name = "Necronomicon"}
    }
})

world.enemies = { copyEnemy(Enemies.Goblin) }
StartCombat.execute(world)

local player = world.player

print("\nPlayer relics:")
for i, relic in ipairs(player.relics) do
    print("  " .. i .. ". id=" .. relic.id .. ", name=" .. relic.name)
end

print("\nChecking Utils.hasRelic:")
print("  Utils.hasRelic(player, 'Necronomicon'): " .. tostring(Utils.hasRelic(player, "Necronomicon")))

StartTurn.execute(world, player)

-- Find Heavy Blade
local heavyBladeCard = findCardById(player.combatDeck, "Heavy_Blade")
print("\nHeavy Blade card found:")
print("  id: " .. heavyBladeCard.id)
print("  cost: " .. heavyBladeCard.cost)
print("  type: " .. heavyBladeCard.type)
print("  state: " .. heavyBladeCard.state)

-- Manually check what buildReplayPlan would return
local DuplicationHelpers = require("Pipelines.PlayCard_DuplicationHelpers")
print("\nBefore playing Heavy Blade:")
print("  player.status.necronomiconThisTurn: " .. tostring(player.status.necronomiconThisTurn))

-- Build replay plan manually before playing
local testCard = copyCard(Cards.HeavyBlade)
testCard.costWhenPlayed = 2  -- Simulate what prepareCardPlay sets
local plan = DuplicationHelpers.buildReplayPlan(world, player, testCard)
print("\nReplay plan (simulated):")
for i, source in ipairs(plan) do
    print("  " .. i .. ". " .. source)
end

print("\n--- Playing Heavy Blade ---")
playCardWithAutoContext(world, player, heavyBladeCard)

print("\n--- Combat Log ---")
for _, entry in ipairs(world.log) do
    print(entry)
end

print("\n--- Final Status ---")
print("player.status.necronomiconThisTurn: " .. tostring(player.status.necronomiconThisTurn))
