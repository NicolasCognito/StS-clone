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

    local result = PlayCard.execute(world, player, headbutt, nil)
    assert(type(result) == "table" and result.needsPostPlay, "Headbutt should request post-play context")

    local postResult = PlayCard.executePostPlay(world, player, headbutt, {strike})
    assert(postResult == true, "Headbutt post-play should finish without replays")
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

    -- Put two cards into discard pile so both post-play executions have options
    strikeA.state = "DISCARD_PILE"
    defend.state = "DISCARD_PILE"

    assert(PlayCard.execute(world, player, doubleTap, nil) == true, "Double Tap should resolve successfully")

    local headbuttResult = PlayCard.execute(world, player, headbutt, nil)
    assert(type(headbuttResult) == "table" and headbuttResult.needsPostPlay, "Headbutt should require post-play when Double Tap is active")
    assert(player.status.doubleTap == 0, "Headbutt should consume the Double Tap stack during play")

    local firstPost = PlayCard.executePostPlay(world, player, headbutt, {strikeA})
    assert(type(firstPost) == "table" and firstPost.needsPostPlay, "First Headbutt post-play should signal another execution due to Double Tap")

    local secondPost = PlayCard.executePostPlay(world, player, headbutt, {defend})
    assert(secondPost == true, "Second Headbutt post-play should finish the replay sequence")

    local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
    assert(deckCards[1] == defend, "Most recent Headbutt selection should be on top of the draw pile")
    assert(deckCards[2] == strikeA, "First Headbutt selection should now be second on the draw pile")
end

print("Headbutt tests passed.")
