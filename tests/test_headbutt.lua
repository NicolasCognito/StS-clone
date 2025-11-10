local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

local function findCard(deck, id)
    for _, card in ipairs(deck) do
        if card.id == id then
            return card
        end
    end
    error("Card " .. id .. " not found in deck")
end

local function createWorldWithDeck(deck)
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        cards = deck,
        relics = {}
    })

    world.enemies = {
        copyEnemy(Enemies.Goblin)
    }

    StartCombat.execute(world)
    return world
end

local function fulfillContext(world, player, override)
    local request = world.combat.contextRequest
    assert(request, "Context request should be populated")

    local context = override or ContextProvider.execute(world, player, request.contextProvider, request.card)
    assert(context, "ContextProvider failed to supply context for " .. (request.card and request.card.name or "unknown card"))

    if request.stability == "stable" then
        world.combat.stableContext = context
    else
        world.combat.tempContext = context
    end

    world.combat.contextRequest = nil
    return context
end

-- Test 1: Single Headbutt should put the chosen discard card on top of the deck
do
    local deck = {
        copyCard(Cards.Headbutt),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend),
        copyCard(Cards.Bash),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend)
    }

    local world = createWorldWithDeck(deck)
    local player = world.player

    local headbutt = findCard(player.combatDeck, "Headbutt")
    local strike = findCard(player.combatDeck, "Strike")

    -- Put Strike into discard pile to target
    strike.state = "DISCARD_PILE"

    -- Enemy targeting
    local result = PlayCard.execute(world, player, headbutt)
    assert(type(result) == "table" and result.needsContext, "Headbutt should request enemy context")
    fulfillContext(world, player)

    -- Discard selection
    result = PlayCard.execute(world, player, headbutt)
    assert(type(result) == "table" and result.needsContext, "Headbutt should request card selection context")
    fulfillContext(world, player, {strike})

    -- Final resolution
    result = PlayCard.execute(world, player, headbutt)
    assert(result == true, "Headbutt should complete successfully")
    assert(strike.state == "DECK", "Headbutt should move the selected card back to the deck")

    local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
    assert(deckCards[1] == strike, "Headbutt should place the selected card on top of the draw pile")
end

-- Test 2: Double Tap + Headbutt should let you queue two cards from discard
do
    local deck = {
        copyCard(Cards.DoubleTap),
        copyCard(Cards.Headbutt),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend),
        copyCard(Cards.Bash),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend)
    }

    local world = createWorldWithDeck(deck)
    local player = world.player

    local doubleTap = findCard(player.combatDeck, "DoubleTap")
    local headbutt = findCard(player.combatDeck, "Headbutt")
    local strikeA = findCard(player.combatDeck, "Strike")
    local defend = findCard(player.combatDeck, "Defend")

    -- Put two cards into discard pile so both additional context collections have options
    strikeA.state = "DISCARD_PILE"
    defend.state = "DISCARD_PILE"

    -- Play Double Tap
    assert(PlayCard.execute(world, player, doubleTap) == true, "Double Tap should resolve successfully")

    -- Enemy targeting
    local result = PlayCard.execute(world, player, headbutt)
    assert(type(result) == "table" and result.needsContext, "Headbutt should request enemy context")
    fulfillContext(world, player)

    -- First discard selection
    result = PlayCard.execute(world, player, headbutt)
    assert(type(result) == "table" and result.needsContext, "Headbutt should request discard selection")
    fulfillContext(world, player, {strikeA})

    -- Finish first execution (should trigger duplication and request another discard)
    result = PlayCard.execute(world, player, headbutt)
    assert(type(result) == "table" and result.needsContext, "Duplication should request a new discard target")
    fulfillContext(world, player, {defend})

    -- Complete duplicated execution
    result = PlayCard.execute(world, player, headbutt)
    assert(result == true, "Second Headbutt execution should complete")
    assert((player.status.doubleTap or 0) == 0, "Double Tap should be consumed")

    local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
    assert(deckCards[1] == defend, "Most recent Headbutt selection should be on top of the draw pile")
    assert(deckCards[2] == strikeA, "First Headbutt selection should now be second on the draw pile")
end

print("Headbutt tests passed.")
