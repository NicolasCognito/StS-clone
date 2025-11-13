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

local function countCardsInState(deck, state)
    local count = 0
    for _, card in ipairs(deck) do
        if card.state == state then
            count = count + 1
        end
    end
    return count
end

local function fulfillContext(world, player, override)
    local request = world.combat.contextRequest
    assert(request, "Context request should exist")

    local context = override or ContextProvider.execute(world, player, request.contextProvider, request.card)
    assert(context, "ContextProvider failed to supply context")

    if request.stability == "stable" then
        world.combat.stableContext = context
    else
        world.combat.tempContext = context
    end

    world.combat.contextRequest = nil
    return context
end

-- Build a deterministic deck so draw order is stable
local deck = {
    copyCard(Cards.DoubleTap),
    copyCard(Cards.DaggerThrow),
    copyCard(Cards.Strike),
    copyCard(Cards.Defend),
    copyCard(Cards.Bash),
    copyCard(Cards.Strike),
    copyCard(Cards.Defend)
}

local world = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = deck,
    relics = {}
})

world.enemies = {
    copyEnemy(Enemies.Goblin)
}

-- Enable NoShuffle for deterministic test
world.NoShuffle = true

StartCombat.execute(world)

local player = world.player
local enemy = world.enemies[1]

local doubleTapCard = findCardById(player.combatDeck, "DoubleTap")
local daggerThrowCard = findCardById(player.combatDeck, "DaggerThrow")

assert(doubleTapCard.state == "HAND", "Double Tap should start in hand for the test")
assert(daggerThrowCard.state == "HAND", "Dagger Throw should start in hand for the test")

assert(PlayCard.execute(world, player, doubleTapCard) == true, "Double Tap failed to resolve")
assert(player.status.doubleTap == 1, "Double Tap should add exactly one stack")

local firstDiscard = findCardById(player.combatDeck, "Strike")
local secondDiscard = findCardById(player.combatDeck, "Defend")
local discardOrder = {firstDiscard, secondDiscard}
local discardIndex = 1

while true do
    local daggerResult = PlayCard.execute(world, player, daggerThrowCard)
    if daggerResult == true then
        break
    end

    assert(type(daggerResult) == "table" and daggerResult.needsContext, "Dagger Throw should request context during resolution")
    local request = world.combat.contextRequest
    assert(request, "Context request should be populated")

    if request.contextProvider.type == "enemy" then
        fulfillContext(world, player)
    else
        local discardCard = discardOrder[discardIndex]
        assert(discardCard, "Unexpected discard request count")
        discardIndex = discardIndex + 1
        fulfillContext(world, player, {discardCard})
    end
end

-- Process any remaining card queue entries (duplications, etc.)
while not world.cardQueue:isEmpty() do
    local entry = world.cardQueue:pop()
    while true do
        local result = PlayCard.resolveQueuedEntry(world, entry)
        if result == true then
            break
        end
        -- Handle context for duplicated plays
        if type(result) == "table" and result.needsContext then
            local request = world.combat.contextRequest
            if request.contextProvider.type == "enemy" then
                fulfillContext(world, player)
            else
                local discardCard = discardOrder[discardIndex]
                assert(discardCard, "Unexpected discard request count during duplication")
                discardIndex = discardIndex + 1
                fulfillContext(world, player, {discardCard})
            end
        end
    end
end

assert(discardIndex == 3, "Dagger Throw should have requested two discard selections (one for each play)")

assert((player.status.doubleTap or 0) == 0, "Double Tap stacks should be consumed after an attack")
assert(enemy.hp == 0, "Enemy should be reduced to 0 HP after taking double damage")

-- Count played cards (DISCARD_PILE + PROCESSING, since cards can be left in PROCESSING after cancellation)
local playedCount = countCardsInState(player.combatDeck, "DISCARD_PILE") + countCardsInState(player.combatDeck, "PROCESSING")
assert(playedCount == 4, "Expected 4 played cards (Double Tap, Dagger Throw, and two discarded cards), got " .. playedCount)

local function countLogEntries(text)
    local total = 0
    for _, entry in ipairs(world.log) do
        if entry == text then
            total = total + 1
        end
    end
    return total
end

assert(countLogEntries("Double Tap triggers!") == 1, "Combat log should record the Double Tap trigger exactly once")
assert(countLogEntries("IronClad dealt 9 damage to Goblin") == 2, "Dagger Throw should deal damage twice when Double Tap triggers")

print("Double Tap integration test passed.")
