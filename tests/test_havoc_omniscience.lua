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
        id = "Watcher",
        maxHp = 70,
        cards = deck,
        relics = {}
    })

    world.player.maxEnergy = 5
    world.player.energy = 5

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

-- Test 1: Havoc should play the top draw card for free and exhaust itself
do
    local deck = {
        copyCard(Cards.Havoc),
        copyCard(Cards.Defend),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend),
        copyCard(Cards.Strike),
        copyCard(Cards.Strike)
    }

    local world = createWorldWithDeck(deck)
    local player = world.player
    local havoc = findCard(player.combatDeck, "Havoc")
    local enemy = world.enemies[1]
    local initialHp = enemy.hp

    local topCard = nil
    for _, card in ipairs(player.combatDeck) do
        if card.state == "DECK" then
            topCard = card
            break
        end
    end
    assert(topCard, "Expected a card to remain in the draw pile")
    assert(topCard.id == "Strike", "Expected Strike to be the top draw card")

    assert(PlayCard.execute(world, player, havoc) == true, "Havoc should resolve successfully")
    assert(havoc.state == "EXHAUSTED_PILE", "Havoc should exhaust after play")
    assert(topCard.state == "DISCARD_PILE", "Top draw card should have been played and discarded")
    assert(enemy.hp == initialHp - topCard.damage, "Enemy should take damage from the Havoc play")
end

-- Test 2: Omniscience should select a draw pile card, play it twice, and exhaust it
do
    local deck = {
        copyCard(Cards.Omniscience),
        copyCard(Cards.Defend),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend),
        copyCard(Cards.Defend),
        copyCard(Cards.Bash)
    }

    local world = createWorldWithDeck(deck)
    local player = world.player
    local omniscience = findCard(player.combatDeck, "Omniscience")
    local enemy = world.enemies[1]

    local target = nil
    for _, card in ipairs(player.combatDeck) do
        if card.id == "Bash" and card.state == "DECK" then
            target = card
            break
        end
    end
    assert(target, "Expected Bash to remain in the draw pile")

    local result = PlayCard.execute(world, player, omniscience)
    assert(type(result) == "table" and result.needsContext, "Omniscience should request a card selection")
    fulfillContext(world, player, {target})

    result = PlayCard.execute(world, player, omniscience)
    assert(result == true, "Omniscience should resolve after context is provided")

    assert(omniscience.state == "EXHAUSTED_PILE", "Omniscience should exhaust itself")
    assert(target.state == "EXHAUSTED_PILE", "Targeted card should be exhausted after Omniscience")
    assert(enemy.hp <= 0, "Enemy should take lethal damage from the double Bash")
end

-- Test 3: Burst interaction - Havoc duplicates once and first auto-played skill is duplicated
do
    local deck = {
        copyCard(Cards.Burst),
        copyCard(Cards.Havoc),
        copyCard(Cards.Strike),
        copyCard(Cards.Strike),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend),
        copyCard(Cards.Defend)
    }

    deck[1]:onUpgrade()  -- Burst+ for 2 stacks

    local world = createWorldWithDeck(deck)
    local player = world.player

    local burst = findCard(player.combatDeck, "Burst")
    local havoc = findCard(player.combatDeck, "Havoc")

    -- Confirm cards started in hand
    assert(burst.state == "HAND" and havoc.state == "HAND", "Burst and Havoc should start in hand")

    -- Top draw pile cards (after initial draw)
    local deckDefends = {}
    for _, card in ipairs(player.combatDeck) do
        if card.id == "Defend" and card.state == "DECK" then
            table.insert(deckDefends, card)
        end
    end
    assert(#deckDefends == 2, "Expected two Defends remaining in draw pile")
    local topDefend = deckDefends[1]
    local secondDefend = deckDefends[2]

    assert(PlayCard.execute(world, player, burst) == true, "Burst should resolve successfully")
    assert((player.status.burst or 0) == 2, "Burst+ should grant 2 Burst stacks")

    assert(PlayCard.execute(world, player, havoc) == true, "Havoc should resolve successfully under Burst")

    assert(topDefend.state == "DISCARD_PILE", "First draw pile card should have been played and discarded")
    assert(secondDefend.state == "DISCARD_PILE", "Second draw pile card should have been played by duplicated Havoc")
    assert((player.status.burst or 0) == 0, "Burst stacks should be consumed after Havoc chain")
    assert(player.block == 15, "First Defend should be duplicated (10 block) and second played once (5 block)")
end

-- Test 4: Havoc should not treat auto-played cards as being in hand
do
    local deck = {
        copyCard(Cards.Havoc),
        copyCard(Cards.DaggerThrow),
        copyCard(Cards.Strike),
        copyCard(Cards.Defend),
        copyCard(Cards.Defend),
        copyCard(Cards.Strike)
    }

    local world = createWorldWithDeck(deck)
    local player = world.player

    local havoc = findCard(player.combatDeck, "Havoc")
    local dagger = findCard(player.combatDeck, "DaggerThrow")

    local strikeTarget = nil
    for _, card in ipairs(player.combatDeck) do
        if card.id == "Strike" then
            strikeTarget = card
            break
        end
    end
    assert(strikeTarget, "Expected a Strike card for discard verification")

    -- Reset all cards to a controlled state
    for _, card in ipairs(player.combatDeck) do
        card.state = "EXHAUSTED_PILE"
    end

    havoc.state = "HAND"
    dagger.state = "DECK"
    strikeTarget.state = "DECK"

    -- Ensure Dagger Throw is on top and Strike directly beneath it
    Utils.moveCardToDeckTop(player.combatDeck, strikeTarget)
    Utils.moveCardToDeckTop(player.combatDeck, dagger)

    local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
    assert(#deckCards == 2, "Expected only Dagger Throw and Strike to remain in deck")

    assert(PlayCard.execute(world, player, havoc) == true, "Havoc should resolve successfully")

    assert(strikeTarget.state == "DISCARD_PILE", "Strike drawn by Dagger Throw should have been discarded")

    local daggerDiscardCount = 0
    for _, entry in ipairs(world.log) do
        if entry == (player.id .. " discarded Dagger Throw") then
            daggerDiscardCount = daggerDiscardCount + 1
        end
    end
    assert(daggerDiscardCount == 1, "Dagger Throw should only be discarded once during cleanup")
end

print("Havoc and Omniscience tests passed.")
