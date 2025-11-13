local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
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
            assert(request, "Context request should exist")

            local context = ContextProvider.execute(world, player, request.contextProvider, request.card)
            assert(context, "Failed to collect context for " .. card.name)

            if request.stability == "stable" then
                world.combat.stableContext = context
            else
                world.combat.tempContext = context
            end

            world.combat.contextRequest = nil
        end
    end
end

print("=== DEBUG: Double Tap + Echo Form ===")

local deck = {
    copyCard(Cards.Strike),
    copyCard(Cards.Defend)
}

local world = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = deck,
    relics = {}
})

world.enemies = { copyEnemy(Enemies.Goblin) }
StartCombat.execute(world)

local player = world.player
local enemy = world.enemies[1]

-- Set up Double Tap + Echo Form
player.status = player.status or {}
player.status.doubleTap = 1

-- Set up Echo Form power (required for duplication system)
player.powers = player.powers or {}
table.insert(player.powers, {id = "EchoForm", stacks = 1})
player.status.echoFormThisTurn = 1

print("Before playing Strike:")
print("  player.status.doubleTap = " .. (player.status.doubleTap or 0))
print("  player.status.echoFormThisTurn = " .. (player.status.echoFormThisTurn or 0))

local strikeCard = findCardById(player.combatDeck, "Strike")
print("  strikeCard._echoFormApplied = " .. tostring(strikeCard._echoFormApplied))
print("  strikeCard.type = " .. strikeCard.type)

-- Manually check what buildReplayPlan would return
local DuplicationHelpers = require("Pipelines.PlayCard_DuplicationHelpers")
local plan = DuplicationHelpers.buildReplayPlan(world, player, strikeCard)
print("\nReplay plan:")
for i, source in ipairs(plan) do
    print("  " .. i .. ". " .. source)
end

print("\nAfter buildReplayPlan:")
print("  player.status.doubleTap = " .. (player.status.doubleTap or 0))
print("  player.status.echoFormThisTurn = " .. (player.status.echoFormThisTurn or 0))

print("\n--- Combat Log ---")
playCardWithAutoContext(world, player, strikeCard)

for _, entry in ipairs(world.log) do
    print(entry)
end

print("\n--- Final Status ---")
print("player.status.doubleTap = " .. (player.status.doubleTap or 0))
print("player.status.echoFormThisTurn = " .. (player.status.echoFormThisTurn or 0))
print("enemy.hp = " .. enemy.hp)
