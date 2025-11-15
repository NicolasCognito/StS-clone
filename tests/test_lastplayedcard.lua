-- TEST: Last Played Card tracking and dependent cards
-- Tests Follow-Up, Sash Whip, and Crush Joints cards
-- These cards have conditional effects based on the type of the last played card

local World = require("World")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")
local Utils = require("utils")

print("=== Testing Last Played Card Tracking ===\n")

-- Helper: play a card to completion, auto-fulfilling context requests.
-- Tests don't run through the full CombatEngine prompt loop, so the
-- separators that wipe stable context require us to respond to context
-- requests manually. Doing it here keeps the production mechanics intact
-- (popping separators would hide real-world bugs) while staying tolerable
-- for tests with a single deterministic target.
local function pickEnemyTarget(world)
    if not world.enemies then
        return nil
    end

    for _, enemy in ipairs(world.enemies) do
        if enemy.hp > 0 then
            return enemy
        end
    end

    return world.enemies[1]
end

local function playCard(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            return true
        end

        assert(type(result) == "table" and result.needsContext,
            "Unexpected PlayCard result when resolving " .. card.name)

        local request = world.combat.contextRequest
        assert(request, "Context request missing for " .. card.name)

        local context = ContextProvider.execute(world, player, request.contextProvider, request.card)

        -- If a card ever requests {type = "enemies"} (should be rare), tests
        -- select the first living enemy manually instead of popping separators,
        -- keeping production context-clearing behavior intact.
        if not context and request.contextProvider and request.contextProvider.type == "enemies" then
            context = pickEnemyTarget(world)
        end

        assert(context, "Failed to supply context for " .. (request.card and request.card.name or "unknown card"))

        if request.stability == "stable" then
            world.combat.stableContext = context
        else
            -- Use indexed tempContext
                local contextId = request.contextId
                world.combat.tempContext[contextId] = context
        end
        world.combat.contextRequest = nil
    end
end

-- Test 1: Follow-Up grants energy when last card was Attack
print("Test 1: Follow-Up grants energy after Attack")
local world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER"
})

local strike = Utils.deepCopyCard(Cards.Strike)
strike.state = "HAND"

local followup = Utils.deepCopyCard(Cards.FollowUp)
followup.state = "HAND"

world.player.masterDeck = {strike, followup}
world.player.combatDeck = {strike, followup}
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

-- Play Strike first
local enemy = world.enemies[1]
playCard(world, world.player, strike)

-- Check last played card
assert(world.lastPlayedCard ~= nil, "lastPlayedCard should be set")
assert(world.lastPlayedCard.type == "ATTACK", "Last played card should be ATTACK")
print("Last played card: " .. world.lastPlayedCard.name .. " (type: " .. world.lastPlayedCard.type .. ")")

-- Record energy before Follow-Up
local energyBefore = world.player.energy
print("Energy before Follow-Up: " .. energyBefore)

-- Play Follow-Up
playCard(world, world.player, followup)

-- Check energy gained (Follow-Up costs 1, grants 1, so net 0 change)
local energyAfter = world.player.energy
print("Energy after Follow-Up: " .. energyAfter)
assert(energyAfter == energyBefore, "Follow-Up should refund its cost after Attack (was " .. energyAfter .. ", expected " .. energyBefore .. ")")

print("✓ Test 1 passed: Follow-Up grants energy after Attack\n")

-- Test 2: Follow-Up doesn't grant energy when last card was Skill
print("Test 2: Follow-Up doesn't grant energy after Skill")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER"
})

local defend = Utils.deepCopyCard(Cards.Defend)
defend.state = "HAND"

followup = Utils.deepCopyCard(Cards.FollowUp)
followup.state = "HAND"

world.player.masterDeck = {defend, followup}
world.player.combatDeck = {defend, followup}
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

-- Play Defend first
playCard(world, world.player, defend)

-- Check last played card
assert(world.lastPlayedCard.type == "SKILL", "Last played card should be SKILL")
print("Last played card: " .. world.lastPlayedCard.name .. " (type: " .. world.lastPlayedCard.type .. ")")

-- Record energy before Follow-Up
energyBefore = world.player.energy
print("Energy before Follow-Up: " .. energyBefore)

-- Play Follow-Up
enemy = world.enemies[1]
playCard(world, world.player, followup)

-- Check energy NOT gained (costs 1, grants 0, net -1)
energyAfter = world.player.energy
print("Energy after Follow-Up: " .. energyAfter)
assert(energyAfter == energyBefore - 1, "Follow-Up should NOT grant energy after Skill (net cost 1)")

print("✓ Test 2 passed: Follow-Up doesn't grant energy after Skill\n")

-- Test 3: Sash Whip applies Weak when last card was Attack
print("Test 3: Sash Whip applies Weak after Attack")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER"
})

strike = Utils.deepCopyCard(Cards.Strike)
strike.state = "HAND"

local sashwhip = Utils.deepCopyCard(Cards.SashWhip)
sashwhip.state = "HAND"

world.player.masterDeck = {strike, sashwhip}
world.player.combatDeck = {strike, sashwhip}
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

-- Play Strike first
enemy = world.enemies[1]
playCard(world, world.player, strike)

print("Last played card: " .. world.lastPlayedCard.name .. " (type: " .. world.lastPlayedCard.type .. ")")

-- Play Sash Whip
playCard(world, world.player, sashwhip)

-- Check enemy has Weak
assert(enemy.status.weak and enemy.status.weak > 0, "Enemy should have Weak after Sash Whip following Attack")
print("Enemy Weak stacks: " .. enemy.status.weak)

print("✓ Test 3 passed: Sash Whip applies Weak after Attack\n")

-- Test 4: Sash Whip doesn't apply Weak when last card was Skill
print("Test 4: Sash Whip doesn't apply Weak after Skill")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER"
})

defend = Utils.deepCopyCard(Cards.Defend)
defend.state = "HAND"

sashwhip = Utils.deepCopyCard(Cards.SashWhip)
sashwhip.state = "HAND"

world.player.masterDeck = {defend, sashwhip}
world.player.combatDeck = {defend, sashwhip}
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

-- Play Defend first
playCard(world, world.player, defend)

print("Last played card: " .. world.lastPlayedCard.name .. " (type: " .. world.lastPlayedCard.type .. ")")

-- Play Sash Whip
enemy = world.enemies[1]
playCard(world, world.player, sashwhip)

-- Check enemy does NOT have Weak
assert(not enemy.status.weak or enemy.status.weak == 0, "Enemy should NOT have Weak after Sash Whip following Skill")
print("Enemy Weak stacks: " .. (enemy.status.weak or 0))

print("✓ Test 4 passed: Sash Whip doesn't apply Weak after Skill\n")

-- Test 5: Crush Joints applies Vulnerable when last card was Skill
print("Test 5: Crush Joints applies Vulnerable after Skill")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER"
})

defend = Utils.deepCopyCard(Cards.Defend)
defend.state = "HAND"

local crushjoints = Utils.deepCopyCard(Cards.CrushJoints)
crushjoints.state = "HAND"

world.player.masterDeck = {defend, crushjoints}
world.player.combatDeck = {defend, crushjoints}
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

-- Play Defend first
playCard(world, world.player, defend)

print("Last played card: " .. world.lastPlayedCard.name .. " (type: " .. world.lastPlayedCard.type .. ")")

-- Play Crush Joints
enemy = world.enemies[1]
playCard(world, world.player, crushjoints)

-- Check enemy has Vulnerable
assert(enemy.status.vulnerable and enemy.status.vulnerable > 0, "Enemy should have Vulnerable after Crush Joints following Skill")
print("Enemy Vulnerable stacks: " .. enemy.status.vulnerable)

print("✓ Test 5 passed: Crush Joints applies Vulnerable after Skill\n")

-- Test 6: Crush Joints doesn't apply Vulnerable when last card was Attack
print("Test 6: Crush Joints doesn't apply Vulnerable after Attack")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER"
})

strike = Utils.deepCopyCard(Cards.Strike)
strike.state = "HAND"

crushjoints = Utils.deepCopyCard(Cards.CrushJoints)
crushjoints.state = "HAND"

world.player.masterDeck = {strike, crushjoints}
world.player.combatDeck = {strike, crushjoints}
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

-- Play Strike first
enemy = world.enemies[1]
playCard(world, world.player, strike)

print("Last played card: " .. world.lastPlayedCard.name .. " (type: " .. world.lastPlayedCard.type .. ")")

-- Play Crush Joints
playCard(world, world.player, crushjoints)

-- Check enemy does NOT have Vulnerable
assert(not enemy.status.vulnerable or enemy.status.vulnerable == 0, "Enemy should NOT have Vulnerable after Crush Joints following Attack")
print("Enemy Vulnerable stacks: " .. (enemy.status.vulnerable or 0))

print("✓ Test 6 passed: Crush Joints doesn't apply Vulnerable after Attack\n")

-- Test 7: Upgraded versions have correct values
print("Test 7: Upgraded versions")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER"
})

strike = Utils.deepCopyCard(Cards.Strike)
strike.state = "HAND"

-- Test upgraded Follow-Up
followup = Utils.deepCopyCard(Cards.FollowUp)
followup:onUpgrade()
followup.upgraded = true
followup.state = "HAND"
assert(followup.damage == 11, "Upgraded Follow-Up should deal 11 damage")

-- Test upgraded Sash Whip
sashwhip = Utils.deepCopyCard(Cards.SashWhip)
sashwhip:onUpgrade()
sashwhip.upgraded = true
sashwhip.state = "HAND"
assert(sashwhip.damage == 10, "Upgraded Sash Whip should deal 10 damage")
assert(sashwhip.weakStacks == 2, "Upgraded Sash Whip should apply 2 Weak")

-- Test upgraded Crush Joints
crushjoints = Utils.deepCopyCard(Cards.CrushJoints)
crushjoints:onUpgrade()
crushjoints.upgraded = true
crushjoints.state = "HAND"
assert(crushjoints.damage == 10, "Upgraded Crush Joints should deal 10 damage")
assert(crushjoints.vulnerableStacks == 2, "Upgraded Crush Joints should apply 2 Vulnerable")

world.player.masterDeck = {strike, sashwhip, crushjoints}
world.player.combatDeck = {strike, sashwhip, crushjoints}
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

-- Play Strike, then Sash Whip
enemy = world.enemies[1]
playCard(world, world.player, strike)
playCard(world, world.player, sashwhip)

-- Check enemy has 2 Weak
assert(enemy.status.weak == 2, "Enemy should have 2 Weak from upgraded Sash Whip (was " .. enemy.status.weak .. ")")
print("Enemy Weak stacks (upgraded): " .. enemy.status.weak)

print("✓ Test 7 passed: Upgraded versions work correctly\n")

-- Test 8: Start of combat has no last played card
print("Test 8: Start of combat has no last played card")
world = World.createWorld({
    playerName = "TestPlayer",
    playerClass = "WATCHER"
})

sashwhip = Utils.deepCopyCard(Cards.SashWhip)
sashwhip.state = "HAND"

world.player.masterDeck = {sashwhip}
world.player.combatDeck = {sashwhip}
world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

-- Check lastPlayedCard is nil
assert(world.lastPlayedCard == nil, "lastPlayedCard should be nil at start of combat")

-- Play Sash Whip as first card
enemy = world.enemies[1]
playCard(world, world.player, sashwhip)

-- Check enemy doesn't have Weak (no previous card)
assert(not enemy.status.weak or enemy.status.weak == 0, "Enemy should NOT have Weak when Sash Whip is first card")

print("✓ Test 8 passed: First card played doesn't trigger conditional effects\n")

print("=== All Last Played Card Tests Passed ===")
