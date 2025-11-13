-- Test for Slime Boss Splitting Mechanic
--
-- This test verifies:
-- 1. Slime Boss changes intent to Split when HP drops below half
-- 2. Boss spawns 2 SpikeSlimes when executing Split intent
-- 3. Boss is marked as dead after splitting

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local StartTurn = require("Pipelines.StartTurn")
local EnemyTakeTurn = require("Pipelines.EnemyTakeTurn")
local EndTurn = require("Pipelines.EndTurn")

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

print("=== Test 1: Slime Boss changes intent when damaged below half HP ===")

-- Setup world with player and Slime Boss
local deck1 = {
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Defend)
}

local world1 = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    hp = 80,
    maxEnergy = 3,
    deck = deck1,
    relics = {}
})

local boss = copyEnemy(Enemies.SlimeBoss)
world1.enemies = {boss}

StartCombat.execute(world1, world1.player, world1.enemies)

print("Boss HP: " .. boss.hp .. "/" .. boss.maxHp)
print("Half HP threshold: " .. boss.maxHp / 2)

-- Start turn and draw cards
StartTurn.execute(world1, world1.player)

-- Attack the boss multiple times to get it below half HP
-- Strike deals 6 damage, boss has 60 HP, need to deal > 30 damage
local strikesPlayed = 0
local handCards = Utils.getCardsByState(world1.player.combatDeck, "HAND")
for _, card in ipairs(handCards) do
    if card.id == "Strike" and strikesPlayed < 6 then
        PlayCard.execute(world1, world1.player, card, boss)

        -- Process all queued events after each card
        while not world1.queue:isEmpty() do
            local event = world1.queue:pop()
            local pipeline = require("Pipelines." .. Utils.eventTypeToPipelineName(event.type))
            pipeline.execute(world1, event)
        end

        strikesPlayed = strikesPlayed + 1
        print("After Strike " .. strikesPlayed .. ": Boss HP = " .. boss.hp)

        -- Check if intent changed to split
        if boss.hp <= boss.maxHp / 2 then
            break
        end
    end
end

-- Verify boss changed intent to split
assert(boss.hasSplit == true, "Boss should have hasSplit flag set")
assert(boss.currentIntent.name == "Split", "Boss should have Split intent, got: " .. (boss.currentIntent.name or "nil"))
print("✓ Boss changed intent to Split when HP dropped below half")

-- End player turn and let boss execute
EndTurn.execute(world1, world1.player)

-- Count enemies before boss acts
local enemiesBefore = 0
for _, enemy in ipairs(world1.enemies) do
    if enemy.hp > 0 then
        enemiesBefore = enemiesBefore + 1
    end
end
print("Alive enemies before boss turn: " .. enemiesBefore)

-- Boss executes split intent
EnemyTakeTurn.execute(world1, boss, world1.player)

-- Process all queued events
while not world1.queue:isEmpty() do
    local event = world1.queue:pop()
    local pipeline = require("Pipelines." .. Utils.eventTypeToPipelineName(event.type))
    pipeline.execute(world1, event)
end

-- Count slimes after split
local slimeCount = 0
local bossStillPresent = false
for _, enemy in ipairs(world1.enemies) do
    if enemy.id == "SpikeSlime" then
        slimeCount = slimeCount + 1
    end
    if enemy.id == "SlimeBoss" then
        bossStillPresent = true
    end
end

print("SpikeSlimes spawned: " .. slimeCount)
print("Boss still present: " .. tostring(bossStillPresent))

assert(slimeCount == 2, "Should have spawned 2 SpikeSlimes, got: " .. slimeCount)
assert(not bossStillPresent, "Boss should be removed after splitting")
print("✓ Slime Boss successfully split into 2 SpikeSlimes")

print("\n=== Test 2: Slime Boss only splits once ===")

-- Setup another test to verify hasSplit flag prevents multiple splits
local deck2 = {
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike)
}

local world2 = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    hp = 80,
    maxEnergy = 3,
    deck = deck2,
    relics = {}
})

local boss2 = copyEnemy(Enemies.SlimeBoss)
world2.enemies = {boss2}

StartCombat.execute(world2, world2.player, world2.enemies)
StartTurn.execute(world2, world2.player)

-- Damage boss below half HP
local handCards2 = Utils.getCardsByState(world2.player.combatDeck, "HAND")
for i = 1, 3 do
    local strike = handCards2[i]
    if strike and strike.id == "Strike" then
        PlayCard.execute(world2, world2.player, strike, boss2)
        while not world2.queue:isEmpty() do
            local event = world2.queue:pop()
            local pipeline = require("Pipelines." .. Utils.eventTypeToPipelineName(event.type))
            pipeline.execute(world2, event)
        end
    end
end

assert(boss2.hasSplit == true, "Boss should have hasSplit flag set after damage")
print("✓ Boss has hasSplit flag set to prevent multiple intent changes")

print("\n=== All Slime Boss Splitting Tests Passed! ===")
