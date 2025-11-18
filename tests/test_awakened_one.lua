-- Test for Awakened One Boss
--
-- This test verifies:
-- 1. Curiosity grants Strength when player plays Power cards
-- 2. Rebirth triggers when Phase 1 HP reaches 0
-- 3. Phase 2 transformation (HP restored, Curiosity removed)
-- 4. Sludge attack adds Void card to draw pile

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local StartTurn = require("Pipelines.StartTurn")
local EnemyTakeTurn = require("Pipelines.EnemyTakeTurn")
local EndTurn = require("Pipelines.EndTurn")
local ProcessEventQueue = require("Pipelines.ProcessEventQueue")

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

print("=== Test 1: Curiosity grants Strength when Power card played ===")

-- Setup world with Awakened One and Power cards
local deck1 = {
    copyCard(Cards.DemonForm),  -- Power card
    copyCard(Cards.Strike)
}

local world1 = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    hp = 80,
    maxEnergy = 10,
    cards = deck1,
    relics = {}
})

local boss = copyEnemy(Enemies.AwakenedOne)
boss.status = {curiosity = 1}  -- Awakened One starts with Curiosity
world1.enemies = {boss}
world1.NoShuffle = true

StartCombat.execute(world1)

print("Boss initial Strength: " .. tostring(boss.status.strength or 0))
print("Boss Curiosity: " .. tostring(boss.status.curiosity or 0))

-- Play DemonForm (Power card)
local hand1 = Utils.getCardsByState(world1.player.combatDeck, "HAND")
local demonForm = nil
for _, card in ipairs(hand1) do
    if card.id == "DemonForm" then
        demonForm = card
        break
    end
end

if demonForm then
    while true do
        local result = PlayCard.execute(world1, world1.player, demonForm)
        if result == true then
            break
        elseif result == false then
            break
        end
    end
    ProcessEventQueue.execute(world1)
end

print("Boss Strength after playing DemonForm: " .. tostring(boss.status.strength or 0))

-- Verify Curiosity triggered
assert(boss.status.strength >= 1, "Boss should have gained Strength from Curiosity")
print("✓ Curiosity grants Strength when Power card is played")

print("\n=== Test 2: Rebirth triggers when Phase 1 HP reaches 0 ===")

-- Setup world
local deck2 = {
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike)
}

local world2 = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    hp = 80,
    maxEnergy = 100,  -- High energy to kill boss
    cards = deck2,
    relics = {}
})

local boss2 = copyEnemy(Enemies.AwakenedOne)
boss2.hp = 30  -- Lower HP for testing
boss2.maxHp = 30
boss2.status = {curiosity = 1}
world2.enemies = {boss2}
world2.NoShuffle = true

StartCombat.execute(world2)

print("Boss Phase: " .. boss2.phase)
print("Boss HP: " .. boss2.hp .. "/" .. boss2.maxHp)
print("Boss can Rebirth: " .. tostring(boss2.canRebirth))

-- Kill the boss (30 HP / 6 per Strike = 5 Strikes)
local DrawCard = require("Pipelines.DrawCard")
local strikesPlayed = 0

while strikesPlayed < 5 and boss2.hp > 0 do
    local hand2 = Utils.getCardsByState(world2.player.combatDeck, "HAND")
    local strike = nil
    for _, card in ipairs(hand2) do
        if card.id == "Strike" then
            strike = card
            break
        end
    end

    if not strike then
        DrawCard.execute(world2, world2.player, 3)
    else
        while true do
            local result = PlayCard.execute(world2, world2.player, strike)
            if result == true then
                break
            end

            if type(result) == "table" and result.needsContext then
                local request = world2.combat.contextRequest
                if request.contextProvider.type == "enemy" then
                    world2.combat.stableContext = boss2
                    world2.combat.contextRequest = nil
                end
            elseif result == false then
                break
            end
        end
        ProcessEventQueue.execute(world2)
        strikesPlayed = strikesPlayed + 1
    end
end

print("\nAfter killing boss:")
print("  Boss HP: " .. boss2.hp .. "/" .. boss2.maxHp)
print("  Boss Phase: " .. boss2.phase)
print("  Boss dead: " .. tostring(boss2.dead))
print("  Boss can Rebirth: " .. tostring(boss2.canRebirth))
print("  Boss has Curiosity: " .. tostring(boss2.status.curiosity))

-- Verify Rebirth occurred
assert(boss2.hp == boss2.maxHp, "Boss should have full HP after Rebirth, got: " .. boss2.hp)
assert(boss2.phase == 2, "Boss should be in Phase 2 after Rebirth")
assert(boss2.canRebirth == false, "Boss should not be able to Rebirth again")
assert(boss2.status.curiosity == nil, "Boss should lose Curiosity after Rebirth")
assert(boss2.dead ~= true, "Boss should not be dead after Rebirth")
print("✓ Rebirth triggers and transforms boss to Phase 2")

print("\n=== Test 3: Phase 2 first move is Dark Echo ===")

-- Boss should select Dark Echo as first move in Phase 2
boss2:selectIntent(world2, world2.player)
print("Boss first intent in Phase 2: " .. (boss2.currentIntent.name or "nil"))

assert(boss2.currentIntent.name == "Dark Echo", "First move in Phase 2 should be Dark Echo")
print("✓ Phase 2 starts with Dark Echo")

print("\n=== Test 4: Sludge adds Void card to draw pile ===")

-- Setup world
local deck4 = {
    copyCard(Cards.Strike)
}

local world4 = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    hp = 80,
    maxEnergy = 10,
    cards = deck4,
    relics = {}
})

local boss4 = copyEnemy(Enemies.AwakenedOne)
boss4.phase = 2  -- Start in Phase 2
world4.enemies = {boss4}

StartCombat.execute(world4)

-- Count Void cards before Sludge
local function countVoidCards(combatDeck)
    local count = 0
    for _, card in ipairs(combatDeck) do
        if card.id == "Void" then
            count = count + 1
        end
    end
    return count
end

local voidsBefore = countVoidCards(world4.player.combatDeck)
print("Void cards before Sludge: " .. voidsBefore)

-- Execute Sludge attack
boss4.intents.sludge(boss4, world4, world4.player)
ProcessEventQueue.execute(world4)

local voidsAfter = countVoidCards(world4.player.combatDeck)
print("Void cards after Sludge: " .. voidsAfter)

assert(voidsAfter == voidsBefore + 1, "Should have 1 more Void card after Sludge")
print("✓ Sludge adds Void card to draw pile")

print("\n=== All Awakened One Tests Passed! ===")
