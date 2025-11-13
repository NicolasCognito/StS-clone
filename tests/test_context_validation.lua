-- TEST: STABLE CONTEXT VALIDATION
-- Verifies that duplicated cards handle enemy death correctly
-- Example: Double Tap + Strike where enemy dies after first strike

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

local function playCardWithAutoContext(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            return true
        end

        -- Handle context request
        if type(result) == "table" and result.needsContext then
            local request = world.combat.contextRequest
            assert(request, "Context request should exist")

            local context = ContextProvider.execute(world, player, request.contextProvider, request.card)
            assert(context, "Failed to collect context for " .. (request.card and request.card.name or "unknown card"))

            if request.stability == "stable" then
                world.combat.stableContext = context
            else
                world.combat.tempContext = context
            end

            world.combat.contextRequest = nil
        end
    end
end

print("\n=== TEST: Strike with Double Tap kills enemy before duplication ===")

-- Create a low HP enemy that will die from first Strike
local deck = {
    copyCard(Cards.DoubleTap),
    copyCard(Cards.Strike),
    copyCard(Cards.Defend)
}

local world = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    cards = deck,
    relics = {}
})

-- Enemy with 5 HP (will die from first Strike which deals 6 damage)
local enemy = copyEnemy(Enemies.Goblin)
enemy.hp = 5
enemy.maxHp = 5
world.enemies = {enemy}

-- Enable NoShuffle for deterministic test
world.NoShuffle = true

StartCombat.execute(world)

local player = world.player

-- Verify cards are in hand
local doubleTapCard = nil
local strikeCard = nil
for _, card in ipairs(player.combatDeck) do
    if card.state == "HAND" then
        if card.id == "DoubleTap" and not doubleTapCard then
            doubleTapCard = card
        elseif card.id == "Strike" and not strikeCard then
            strikeCard = card
        end
    end
end

assert(doubleTapCard, "Double Tap should be in hand")
assert(strikeCard, "Strike should be in hand")

-- Play Double Tap
playCardWithAutoContext(world, player, doubleTapCard)
assert(player.status.doubleTap == 1, "Double Tap should add exactly one stack")

-- Play Strike (will be duplicated by Double Tap, but enemy dies from first hit)
playCardWithAutoContext(world, player, strikeCard)

-- Verify enemy is dead
assert(enemy.hp <= 0, "Enemy should be dead after first Strike")

-- Check that Double Tap was consumed (even though duplication was cancelled)
assert((player.status.doubleTap or 0) == 0, "Double Tap stacks should be consumed")

-- Check logs for expected behavior
local foundDoubleTapReady = false
local foundCancellation = false
for _, logEntry in ipairs(world.log) do
    if string.match(logEntry, "Double Tap readied") then
        foundDoubleTapReady = true
    end
    -- The duplicated Strike should be cancelled
    if string.match(logEntry, "cancel") or string.match(logEntry, "invalid") then
        foundCancellation = true
    end
end

print("Found Double Tap ready: " .. tostring(foundDoubleTapReady))
print("Found cancellation: " .. tostring(foundCancellation))

-- Print last 10 log entries for debugging
print("\n--- Last 10 Log Entries ---")
local startIdx = math.max(1, #world.log - 9)
for i = startIdx, #world.log do
    print(world.log[i])
end

assert(foundDoubleTapReady, "Should find Double Tap ready message in logs")
assert(foundCancellation, "Should find cancellation message when enemy dies")

print("\n✓ Test passed! Double Tap + Strike handled enemy death correctly")
print("\n=== CONTEXT VALIDATION TEST PASSED ===")
