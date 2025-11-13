local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")
local ProcessEventQueue = require("Pipelines.ProcessEventQueue")

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

print("=== DEBUG 2: Card Queue Processing ===")

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
player.powers = player.powers or {}
table.insert(player.powers, {id = "EchoForm", stacks = 1})
player.status.echoFormThisTurn = 1

local strikeCard = findCardById(player.combatDeck, "Strike")

print("Before PlayCard.execute:")
print("  Card queue empty? " .. tostring(world.cardQueue:isEmpty()))

-- Call PlayCard.execute but manually step through it
print("\n--- Calling PlayCard.execute ---")
local result = PlayCard.execute(world, player, strikeCard)

print("\nAfter PlayCard.execute:")
print("  Result: " .. tostring(result))
print("  Card queue empty? " .. tostring(world.cardQueue:isEmpty()))

-- Check card queue contents
if not world.cardQueue:isEmpty() then
    print("\n  Card queue contents:")
    local tempEntries = {}
    while not world.cardQueue:isEmpty() do
        local entry = world.cardQueue:pop()
        table.insert(tempEntries, entry)
        print("    - Entry: isInitial=" .. tostring(entry.isInitial) .. ", replaySource=" .. tostring(entry.replaySource) .. ", phase=" .. tostring(entry.phase))
    end

    -- Put them back in reverse order
    for i = #tempEntries, 1, -1 do
        world.cardQueue:push(tempEntries[i])
    end
end

print("\n--- Combat Log So Far ---")
for _, entry in ipairs(world.log) do
    print(entry)
end

-- Now handle context if needed
print("\n--- Handling Context ---")
while type(result) == "table" and result.needsContext do
    local request = world.combat.contextRequest
    print("Context request type: " .. (request and request.contextProvider.type or "nil"))

    local context = ContextProvider.execute(world, player, request.contextProvider, request.card)

    if request.stability == "stable" then
        world.combat.stableContext = context
    else
        world.combat.tempContext = context
    end

    world.combat.contextRequest = nil

    -- Continue execution
    result = PlayCard.execute(world, player, strikeCard)
    print("After context fulfillment, result: " .. tostring(result))
    print("  Card queue empty? " .. tostring(world.cardQueue:isEmpty()))
end

print("\n--- Final Combat Log ---")
for _, entry in ipairs(world.log) do
    print(entry)
end

print("\n--- Final Status ---")
print("enemy.hp = " .. enemy.hp)
print("player.status.doubleTap = " .. (player.status.doubleTap or 0))
print("player.status.echoFormThisTurn = " .. (player.status.echoFormThisTurn or 0))
