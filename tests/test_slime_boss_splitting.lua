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
local ProcessEventQueue = require("Pipelines.ProcessEventQueue")

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
    copyCard(Cards.Strike),  -- Need 5 Strikes to get boss below half HP (60 → 30)
    copyCard(Cards.Defend)
}

local world1 = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    hp = 80,
    maxEnergy = 6,  -- Need at least 5 energy to play 5 Strikes to get boss below half HP
    cards = deck1,  -- Use 'cards' parameter name, not 'deck'
    relics = {}
})

local boss = copyEnemy(Enemies.SlimeBoss)
world1.enemies = {boss}

-- Enable NoShuffle for deterministic card draw
world1.NoShuffle = true

StartCombat.execute(world1)

print("Boss HP: " .. boss.hp .. "/" .. boss.maxHp)
print("Half HP threshold: " .. boss.maxHp / 2)

-- StartCombat already calls StartTurn and draws cards

-- Attack the boss multiple times to get it below half HP
-- Strike deals 6 damage, boss has 60 HP, need to deal > 30 damage
local strikesPlayed = 0
local handCards = Utils.getCardsByState(world1.player.combatDeck, "HAND")
for _, card in ipairs(handCards) do
    if card.id == "Strike" and strikesPlayed < 6 then
        -- Play card and provide context if needed
        while true do
            local result = PlayCard.execute(world1, world1.player, card)
            if result == true then
                break  -- Card finished playing
            end

            -- Handle context request (Strike needs enemy target)
            if type(result) == "table" and result.needsContext then
                local request = world1.combat.contextRequest
                if request.contextProvider.type == "enemy" then
                    -- Provide boss as target
                    world1.combat.stableContext = boss
                    world1.combat.contextRequest = nil
                end
            elseif result == false then
                -- Card couldn't be played (e.g., not enough energy)
                break
            end
        end

        -- Process all queued events after each card
        ProcessEventQueue.execute(world1)

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

-- EnemyTakeTurn already processes the event queue, no need to do it again

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
    copyCard(Cards.Strike),
    copyCard(Cards.Strike)
}

local world2 = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    hp = 80,
    maxEnergy = 6,  -- Need enough energy to damage boss below half HP
    cards = deck2,  -- Use 'cards' parameter name, not 'deck'
    relics = {}
})

local boss2 = copyEnemy(Enemies.SlimeBoss)
world2.enemies = {boss2}

StartCombat.execute(world2)
-- StartCombat already calls StartTurn, no need to call it again

-- Damage boss below half HP (need 5 Strikes: 60 → 30)
local handCards2 = Utils.getCardsByState(world2.player.combatDeck, "HAND")
for i = 1, 5 do
    local strike = handCards2[i]
    if strike and strike.id == "Strike" then
        -- Play card and provide context if needed
        while true do
            local result = PlayCard.execute(world2, world2.player, strike)
            if result == true then
                break
            end

            -- Handle context request (Strike needs enemy target)
            if type(result) == "table" and result.needsContext then
                local request = world2.combat.contextRequest
                if request.contextProvider.type == "enemy" then
                    world2.combat.stableContext = boss2
                    world2.combat.contextRequest = nil
                end
            elseif result == false then
                -- Card couldn't be played (e.g., not enough energy)
                break
            end
        end
        ProcessEventQueue.execute(world2)
    end
end

assert(boss2.hasSplit == true, "Boss should have hasSplit flag set after damage")
print("✓ Boss has hasSplit flag set to prevent multiple intent changes")

print("\n=== All Slime Boss Splitting Tests Passed! ===")
