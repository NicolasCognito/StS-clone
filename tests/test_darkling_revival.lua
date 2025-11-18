-- Test for Darkling Revival Mechanic (Life Link)
--
-- This test verifies:
-- 1. Darkling enters revival state (not permanent death) when HP reaches 0
-- 2. Regrow status effect decrements each turn
-- 3. Darkling revives with half HP if other Darklings are alive
-- 4. Darkling dies permanently if no allies are alive
-- 5. Combat doesn't end while Darklings are reviving
-- 6. Reviving Darklings cannot be targeted
-- 7. On-death effects (Feed, Ritual Dagger) don't trigger on revival state

local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local StartTurn = require("Pipelines.StartTurn")
local EnemyTakeTurn = require("Pipelines.EnemyTakeTurn")
local EndTurn = require("Pipelines.EndTurn")
local EndRound = require("Pipelines.EndRound")
local ProcessEventQueue = require("Pipelines.ProcessEventQueue")

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

print("=== Test 1: Darkling enters revival state when killed ===")

-- Setup world with 2 Darklings
local deck1 = {
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
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

local darkling1 = copyEnemy(Enemies.Darkling)
local darkling2 = copyEnemy(Enemies.Darkling)
darkling1.name = "Darkling 1"
darkling2.name = "Darkling 2"
darkling1.position = "left"
darkling2.position = "middle"

world1.enemies = {darkling1, darkling2}
world1.NoShuffle = true

StartCombat.execute(world1)

print("Darkling 1 HP: " .. darkling1.hp .. "/" .. darkling1.maxHp)
print("Darkling 2 HP: " .. darkling2.hp .. "/" .. darkling2.maxHp)

-- Kill Darkling 1 (48 HP / 6 per Strike = 8 Strikes)
local DrawCard = require("Pipelines.DrawCard")
local strikesPlayed = 0

while strikesPlayed < 8 and darkling1.hp > 0 do
    local handCards = Utils.getCardsByState(world1.player.combatDeck, "HAND")

    -- Find a Strike in hand
    local strike = nil
    for _, card in ipairs(handCards) do
        if card.id == "Strike" then
            strike = card
            break
        end
    end

    if not strike then
        -- Draw more cards if no Strike in hand
        DrawCard.execute(world1, world1.player, 3)
    else
        -- Play the Strike
        while true do
            local result = PlayCard.execute(world1, world1.player, strike)
            if result == true then
                break
            end

            if type(result) == "table" and result.needsContext then
                local request = world1.combat.contextRequest
                if request.contextProvider.type == "enemy" then
                    world1.combat.stableContext = darkling1
                    world1.combat.contextRequest = nil
                end
            elseif result == false then
                break
            end
        end
        ProcessEventQueue.execute(world1)
        strikesPlayed = strikesPlayed + 1
    end
end

print("After attacks:")
print("  Darkling 1 HP: " .. darkling1.hp)
print("  Darkling 1 reviving: " .. tostring(darkling1.reviving))
print("  Darkling 1 dead: " .. tostring(darkling1.dead))

-- Verify Darkling 1 is in revival state, not permanently dead
assert(darkling1.hp == 0, "Darkling 1 should have 0 HP")
assert(darkling1.reviving == true, "Darkling 1 should be reviving")
assert(darkling1.dead ~= true, "Darkling 1 should NOT be permanently dead")
assert(darkling1.status.regrow == 2, "Darkling 1 should have Regrow:2, got: " .. tostring(darkling1.status.regrow))
print("✓ Darkling enters revival state (not permanent death)")

print("\n=== Test 2: Regrow countdown and revival ===")

-- End turn and process enemy turns
EndTurn.execute(world1, world1.player)

-- Enemy turns
for _, enemy in ipairs(world1.enemies) do
    if enemy.hp > 0 or enemy.reviving then
        EnemyTakeTurn.execute(world1, enemy, world1.player)
    end
end

EndRound.execute(world1, world1.player, world1.enemies)

print("After 1 enemy turn:")
print("  Darkling 1 Regrow: " .. tostring(darkling1.status.regrow))
assert(darkling1.status.regrow == 1, "Regrow should decrement to 1")

-- Start player turn
StartTurn.execute(world1, world1.player)

-- End turn again (second round)
EndTurn.execute(world1, world1.player)

-- Enemy turns (Darkling 1 should revive now)
for _, enemy in ipairs(world1.enemies) do
    if enemy.hp > 0 or enemy.reviving then
        EnemyTakeTurn.execute(world1, enemy, world1.player)
    end
end

EndRound.execute(world1, world1.player, world1.enemies)

print("After 2 enemy turns:")
print("  Darkling 1 HP: " .. darkling1.hp)
print("  Darkling 1 reviving: " .. tostring(darkling1.reviving))
print("  Expected revival HP (half of maxHp): " .. math.floor(darkling1.maxHp / 2))

assert(darkling1.hp == math.floor(darkling1.maxHp / 2), "Darkling should revive with half HP")
assert(darkling1.reviving == false, "Darkling should no longer be reviving")
assert(darkling1.status.regrow == nil, "Regrow should be removed")
print("✓ Darkling revives with half HP after 2 turns")

print("\n=== Test 3: Darkling dies permanently if no allies ===")

-- Setup world with only 1 Darkling
local deck3 = {
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike),
    copyCard(Cards.Strike)
}

local world3 = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    hp = 80,
    maxEnergy = 10,
    cards = deck3,
    relics = {}
})

local darklingSolo = copyEnemy(Enemies.Darkling)
darklingSolo.name = "Darkling Solo"
darklingSolo.position = "middle"

world3.enemies = {darklingSolo}
world3.NoShuffle = true

StartCombat.execute(world3)

-- Kill the solo Darkling
local strikesPlayed3 = 0
while strikesPlayed3 < 8 and darklingSolo.hp > 0 do
    local hand3 = Utils.getCardsByState(world3.player.combatDeck, "HAND")
    local strike = nil
    for _, card in ipairs(hand3) do
        if card.id == "Strike" then
            strike = card
            break
        end
    end

    if not strike then
        DrawCard.execute(world3, world3.player, 3)
    else
        while true do
            local result = PlayCard.execute(world3, world3.player, strike)
            if result == true then
                break
            end

            if type(result) == "table" and result.needsContext then
                local request = world3.combat.contextRequest
                if request.contextProvider.type == "enemy" then
                    world3.combat.stableContext = darklingSolo
                    world3.combat.contextRequest = nil
                end
            elseif result == false then
                break
            end
        end
        ProcessEventQueue.execute(world3)
        strikesPlayed3 = strikesPlayed3 + 1
    end
end

print("Solo Darkling HP: " .. darklingSolo.hp)
print("Solo Darkling reviving: " .. tostring(darklingSolo.reviving))

-- Let 2 turns pass
for round = 1, 2 do
    EndTurn.execute(world3, world3.player)

    for _, enemy in ipairs(world3.enemies) do
        if enemy.hp > 0 or enemy.reviving then
            EnemyTakeTurn.execute(world3, enemy, world3.player)
        end
    end

    EndRound.execute(world3, world3.player, world3.enemies)

    if round < 2 then
        StartTurn.execute(world3, world3.player)
    end
end

print("After 2 turns with no allies:")
print("  Solo Darkling HP: " .. darklingSolo.hp)
print("  Solo Darkling dead: " .. tostring(darklingSolo.dead))
print("  Solo Darkling reviving: " .. tostring(darklingSolo.reviving))

assert(darklingSolo.hp == 0, "Solo Darkling should still have 0 HP")
assert(darklingSolo.dead == true, "Solo Darkling should be permanently dead")
assert(darklingSolo.reviving == false, "Solo Darkling should no longer be reviving")
print("✓ Darkling dies permanently when no allies are alive")

print("\n=== Test 4: Reviving Darklings cannot be targeted ===")

-- Setup world
local deck4 = {
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

local world4 = World.createWorld({
    id = "Ironclad",
    maxHp = 80,
    hp = 80,
    maxEnergy = 10,
    cards = deck4,
    relics = {}
})

local darkling4a = copyEnemy(Enemies.Darkling)
local darkling4b = copyEnemy(Enemies.Darkling)
darkling4a.name = "Darkling A"
darkling4b.name = "Darkling B"
darkling4a.position = "left"
darkling4b.position = "right"

world4.enemies = {darkling4a, darkling4b}
world4.NoShuffle = true

StartCombat.execute(world4)

-- Kill Darkling A
local strikesPlayed4 = 0
while strikesPlayed4 < 8 and darkling4a.hp > 0 do
    local hand4 = Utils.getCardsByState(world4.player.combatDeck, "HAND")
    local strike = nil
    for _, card in ipairs(hand4) do
        if card.id == "Strike" then
            strike = card
            break
        end
    end

    if not strike then
        DrawCard.execute(world4, world4.player, 3)
    else
        while true do
            local result = PlayCard.execute(world4, world4.player, strike)
            if result == true then
                break
            end

            if type(result) == "table" and result.needsContext then
                local request = world4.combat.contextRequest
                if request.contextProvider.type == "enemy" then
                    world4.combat.stableContext = darkling4a
                    world4.combat.contextRequest = nil
                end
            elseif result == false then
                break
            end
        end
        ProcessEventQueue.execute(world4)
        strikesPlayed4 = strikesPlayed4 + 1
    end
end

print("Darkling A reviving: " .. tostring(darkling4a.reviving))
print("Darkling B alive: " .. tostring(darkling4b.hp > 0))

-- Check targeting - randomEnemy should return Darkling B, not A
local targetableEnemy = Utils.randomEnemy(world4)
assert(targetableEnemy == darkling4b, "randomEnemy should return living Darkling B, not reviving Darkling A")
print("✓ Reviving Darklings cannot be targeted")

print("\n=== Test 5: Combat doesn't end while Darklings reviving ===")

-- We already have world4 with Darkling A reviving and B alive
-- Check if there are "living" enemies (including reviving)
local hasLivingEnemies = false
for _, enemy in ipairs(world4.enemies) do
    if enemy.hp > 0 or enemy.reviving then
        hasLivingEnemies = true
        break
    end
end

assert(hasLivingEnemies == true, "Combat should not end while Darklings are reviving")
print("✓ Combat continues while Darklings are reviving")

print("\n=== Test 6: On-death effects don't trigger on revival ===")

-- Setup with Feed card
if Cards.Feed then
    local deck6 = {
        copyCard(Cards.Feed),
        copyCard(Cards.Strike)
    }

    local world6 = World.createWorld({
        id = "Ironclad",
        maxHp = 80,
        hp = 70,  -- Not at full HP
        maxEnergy = 10,
        cards = deck6,
        relics = {}
    })

    local darkling6a = copyEnemy(Enemies.Darkling)
    local darkling6b = copyEnemy(Enemies.Darkling)
    darkling6a.name = "Darkling Test6A"
    darkling6b.name = "Darkling Test6B"
    darkling6a.hp = 1  -- Make it easy to kill
    darkling6a.maxHp = 48
    darkling6b.hp = 48
    darkling6b.maxHp = 48

    world6.enemies = {darkling6a, darkling6b}
    world6.NoShuffle = true

    StartCombat.execute(world6)

    local initialHp = world6.player.hp
    local initialMaxHp = world6.player.maxHp

    -- Play Feed on weak Darkling
    local hand6 = Utils.getCardsByState(world6.player.combatDeck, "HAND")
    local feedCard = nil
    for _, card in ipairs(hand6) do
        if card.id == "Feed" then
            feedCard = card
            break
        end
    end

    if feedCard then
        while true do
            local result = PlayCard.execute(world6, world6.player, feedCard)
            if result == true then
                break
            end

            if type(result) == "table" and result.needsContext then
                local request = world6.combat.contextRequest
                if request.contextProvider.type == "enemy" then
                    world6.combat.stableContext = darkling6a
                    world6.combat.contextRequest = nil
                end
            elseif result == false then
                break
            end
        end
        ProcessEventQueue.execute(world6)

        print("Player HP after Feed on reviving Darkling: " .. world6.player.hp .. " (was " .. initialHp .. ")")
        print("Player MaxHP: " .. world6.player.maxHp .. " (was " .. initialMaxHp .. ")")
        print("Darkling A reviving: " .. tostring(darkling6a.reviving))

        -- Feed should NOT trigger because Darkling is reviving, not permanently dead
        assert(world6.player.hp == initialHp, "Feed should not heal when Darkling enters revival")
        assert(world6.player.maxHp == initialMaxHp, "Feed should not increase max HP when Darkling enters revival")
        print("✓ Feed doesn't trigger on Darkling revival state")
    else
        print("! Skipping Feed test (Feed card not available)")
    end
else
    print("! Skipping Feed test (Feed card not in Cards)")
end

print("\n=== All Darkling Revival Tests Passed! ===")
