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

StartCombat.execute(world)

local player = world.player
local enemy = world.enemies[1]

local doubleTapCard = findCardById(player.combatDeck, "DoubleTap")
local daggerThrowCard = findCardById(player.combatDeck, "DaggerThrow")

assert(doubleTapCard.state == "HAND", "Double Tap should start in hand for the test")
assert(daggerThrowCard.state == "HAND", "Dagger Throw should start in hand for the test")

assert(PlayCard.execute(world, player, doubleTapCard, nil) == true, "Double Tap failed to resolve")
assert(player.status.doubleTap == 1, "Double Tap should add exactly one stack")

local daggerResult = PlayCard.execute(world, player, daggerThrowCard, nil)
assert(type(daggerResult) == "table" and daggerResult.needsPostPlay, "Dagger Throw should require post-play selection")

local postResultFirst = PlayCard.executePostPlay(world, player, daggerThrowCard, nil)
assert(type(postResultFirst) == "table" and postResultFirst.needsPostPlay, "First discard should request a replay due to Double Tap")

local postResultSecond = PlayCard.executePostPlay(world, player, daggerThrowCard, nil)
assert(postResultSecond == true, "Second post-play execution should finish the sequence")

assert((player.status.doubleTap or 0) == 0, "Double Tap stacks should be consumed after an attack")
assert(enemy.hp == 0, "Enemy should be reduced to 0 HP after taking double damage")

local discardedCount = countCardsInState(player.combatDeck, "DISCARD_PILE")
assert(discardedCount == 4, "Expected 4 cards in discard pile (Double Tap, Dagger Throw, and two discarded cards)")

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
