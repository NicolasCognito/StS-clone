local World = require("World")
local MapEvents = require("Data.mapevents")
local Map_ProcessQueue = require("Pipelines.Map_ProcessQueue")

local Merchant = MapEvents.Merchant

local function createWorld(gold)
    local world = World.createWorld({
        id = "IronClad",
        gold = gold or 0,
        cards = {},
        relics = {}
    })

    world.player.masterDeck = {}
    world.player.relics = world.player.relics or {}
    world.player.gold = gold or 0
    world.log = {}
    world.mapEvent = {
        merchant = {
            cards = {},
            relics = {},
            cardsGenerated = true,
            relicsGenerated = true
        }
    }

    return world
end

local function drainMapQueue(world, limit)
    limit = limit or 50
    local iterations = 0

    while world.mapQueue and not world.mapQueue:isEmpty() do
        Map_ProcessQueue.execute(world)
        iterations = iterations + 1
        assert(iterations <= limit, "Map queue failed to drain")
    end
end

-- Test 1: Uncommon cards should cost 75 gold
do
    local world = createWorld(100)
    world.mapEvent.merchant.cards[1] = {
        id = "Test_Uncommon",
        name = "Test Uncommon",
        rarity = "UNCOMMON",
        type = "SKILL"
    }

    local result = Merchant.nodes.buy_card_1.onEnter(world)
    assert(result == "shop", "Buying a card should return to the shop")

    drainMapQueue(world)

    assert(world.player.gold == 25, "Uncommon card purchases should spend 75 gold")
    assert(world.mapEvent.merchant.cards[1] == nil, "Purchased card slot should be cleared")
    assert(#world.player.masterDeck == 1, "Purchased cards should be added to the master deck")
end

-- Test 2: Rare cards should cost 150 gold
do
    local world = createWorld(200)
    world.mapEvent.merchant.cards[2] = {
        id = "Test_Rare",
        name = "Test Rare",
        rarity = "RARE",
        type = "ATTACK"
    }

    Merchant.nodes.buy_card_2.onEnter(world)
    drainMapQueue(world)

    assert(world.player.gold == 50, "Rare card purchases should spend 150 gold")
end

-- Test 3: Relics should always cost the default relic price (150 gold)
do
    local world = createWorld(200)
    world.mapEvent.merchant.relics[1] = {
        id = "TestRelic",
        name = "Test Relic"
    }

    Merchant.nodes.buy_relic_1.onEnter(world)
    drainMapQueue(world)

    assert(world.player.gold == 50, "Relic purchases should spend the default relic price")
    assert(world.player.relics[#world.player.relics].id == "TestRelic", "Relic should be added to the player's collection")
    assert(world.mapEvent.merchant.relics[1] == nil, "Purchased relic slot should be cleared")
end

print("Merchant map event tests passed.")
