local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")

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

    -- First call: Headbutt requests enemy context
    local result = PlayCard.execute(world, player, headbutt)
    assert(type(result) == "table" and result.needsContext, "Headbutt should request enemy context")
    assert(world.combat.contextRequest ~= nil, "Context request should be set")

    -- Provide enemy context
    world.combat.latestContext = world.enemies[1]
    world.combat.stableContext = world.enemies[1]
    world.combat.contextRequest = nil
    world.combat.contextCollected = true

    -- Second call: Headbutt plays and requests additional context for card selection
    result = PlayCard.execute(world, player, headbutt)
    assert(type(result) == "table" and result.needsContext, "Headbutt should request additional context for card selection")
    assert(world.combat.contextRequest ~= nil, "Context request for card selection should be set")

    -- Provide card selection context
    world.combat.latestContext = {strike}
    world.combat.tempContext = {strike}
    world.combat.contextRequest = nil

    -- Third call: Headbutt completes the discard effect
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

    -- First call: Headbutt requests enemy context
    local result = PlayCard.execute(world, player, headbutt)
    assert(type(result) == "table" and result.needsContext, "Headbutt should request enemy context")

    -- Provide enemy context
    world.combat.latestContext = world.enemies[1]
    world.combat.stableContext = world.enemies[1]
    world.combat.contextRequest = nil

    -- Second call: Headbutt plays first time and requests card selection
    result = PlayCard.execute(world, player, headbutt)
    assert(type(result) == "table" and result.needsContext, "Headbutt should request card selection context")
    assert(player.status.doubleTap == 0, "Headbutt should consume the Double Tap stack during play")

    -- Provide first card selection
    world.combat.latestContext = {strikeA}
    world.combat.tempContext = {strikeA}
    world.combat.contextRequest = nil

    -- Third call: Complete first execution, then duplication triggers and requests new card selection (temp context)
    result = PlayCard.execute(world, player, headbutt)
    assert(type(result) == "table" and result.needsContext and result.isDuplication, "Headbutt duplication should request new card context")

    -- Provide second card selection
    world.combat.latestContext = {defend}
    world.combat.tempContext = {defend}
    world.combat.contextRequest = nil

    -- Fourth call: Complete second execution
    result = PlayCard.execute(world, player, headbutt)
    assert(result == true, "Second Headbutt execution should complete")

    local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
    assert(deckCards[1] == defend, "Most recent Headbutt selection should be on top of the draw pile")
    assert(deckCards[2] == strikeA, "First Headbutt selection should now be second on the draw pile")
end

print("Headbutt tests passed.")
