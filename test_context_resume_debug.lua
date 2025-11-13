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

local function labeledCard(template, label)
    local card = copyCard(template)
    card._testLabel = label
    return card
end

local function findCardById(deck, cardId)
    for _, card in ipairs(deck) do
        if card.id == cardId then
            return card
        end
    end
    error("Card " .. cardId .. " not found in deck")
end

local function findCardByLabel(deck, label)
    for _, card in ipairs(deck) do
        if card._testLabel == label then
            return card
        end
    end
    error("Card with label " .. label .. " not found")
end

local function playCardWithAutoContext(world, player, card)
    print("\n--- Starting playCardWithAutoContext ---")
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            print("PlayCard.execute returned true, done")
            return true
        end

        if type(result) == "table" and result.needsContext then
            local request = world.combat.contextRequest
            print("Context requested: type=" .. request.contextProvider.type .. ", stability=" .. request.stability)

            local context = ContextProvider.execute(world, player, request.contextProvider, request.card)

            if request.contextProvider.type == "cards" then
                print("  Selected " .. #context .. " card(s):")
                for i, c in ipairs(context) do
                    print("    " .. i .. ". " .. c.name .. " (label=" .. tostring(c._testLabel) .. ", state=" .. c.state .. ")")
                end
            end

            if request.stability == "stable" then
                world.combat.stableContext = context
            else
                world.combat.tempContext = context
            end

            world.combat.contextRequest = nil
        end
    end
end

print("=== DEBUG: Context Resume for Duplications ===")

local deck = {
    copyCard(Cards.DaggerThrow),
    labeledCard(Cards.Defend, "DiscardA"),
    labeledCard(Cards.Strike, "DiscardB"),
    copyCard(Cards.Defend),
    copyCard(Cards.Strike),
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

-- Add NoShuffle to make the test deterministic
world.NoShuffle = true

StartCombat.execute(world)

local player = world.player

print("\nCards in hand after StartCombat:")
local handCards = Utils.getCardsByState(player.combatDeck, "HAND")
for i, card in ipairs(handCards) do
    print("  " .. i .. ". " .. card.name .. " (id=" .. card.id .. ", label=" .. tostring(card._testLabel) .. ")")
end

player.status = player.status or {}
player.status.duplicationPotion = 1

local daggerThrow = findCardById(player.combatDeck, "DaggerThrow")
local discardA = findCardByLabel(player.combatDeck, "DiscardA")
local discardB = findCardByLabel(player.combatDeck, "DiscardB")

print("\nBefore playing Dagger Throw:")
print("  discardA.state = " .. discardA.state)
print("  discardB.state = " .. discardB.state)

playCardWithAutoContext(world, player, daggerThrow)

print("\nAfter playing Dagger Throw:")
print("  discardA.state = " .. discardA.state)
print("  discardB.state = " .. discardB.state)

print("\n--- Combat Log ---")
for _, entry in ipairs(world.log) do
    print(entry)
end
