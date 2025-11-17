-- TEST: Time Eater Boss
-- Verifies Time Warp mechanic, attack patterns, and Haste ability

local lu = require('luaunit')
local WorldBuilder = require("World")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
local EnemyTakeTurn = require("Pipelines.EnemyTakeTurn")
local EndTurn = require("Pipelines.EndTurn")
local StartTurn = require("Pipelines.StartTurn")

TestTimeEater = {}

function TestTimeEater:setUp()
    self.world = WorldBuilder.createWorld()
    self.player = self.world.player

    -- Load enemies
    local Enemies = require("Data.enemies")
    self.timeEater = Enemies.TimeEater

    -- Start combat
    StartCombat.execute(self.world, self.player, {self.timeEater})
    ProcessEventQueue.execute(self.world)
end

function TestTimeEater:testTimeWarpInitialization()
    -- Time Eater should start with Time Warp at 12
    lu.assertEquals(self.timeEater.status.time_warp, 12)
end

function TestTimeEater:testTimeWarpDecrement()
    -- Play a card and verify Time Warp decrements
    local Cards = require("Data.cards")
    local strike = Cards.Strike

    -- Add Strike to hand
    table.insert(self.player.hand, strike)

    -- Play the card
    PlayCard.execute(self.world, self.player, strike)
    ProcessEventQueue.execute(self.world)

    -- Time Warp should have decremented to 11
    lu.assertEquals(self.timeEater.status.time_warp, 11)
end

function TestTimeEater:testTimeWarpTrigger()
    -- Play 12 cards to trigger Time Warp
    local Cards = require("Data.cards")

    -- Add 12 Strikes to hand
    for i = 1, 12 do
        table.insert(self.player.hand, Cards.Strike)
    end

    local initialStrength = self.timeEater.status.strength or 0

    -- Play 11 cards (shouldn't trigger yet)
    for i = 1, 11 do
        PlayCard.execute(self.world, self.player, self.player.hand[1])
        ProcessEventQueue.execute(self.world)
    end

    -- Time Warp should be at 1
    lu.assertEquals(self.timeEater.status.time_warp, 1)

    -- Turn should still be active
    lu.assertNil(self.world.combat.endTurnComplete)

    -- Play 12th card - should trigger Time Warp
    PlayCard.execute(self.world, self.player, self.player.hand[1])
    ProcessEventQueue.execute(self.world)

    -- Time Warp should reset to 12
    lu.assertEquals(self.timeEater.status.time_warp, 12)

    -- Time Eater should have gained +2 Strength
    local newStrength = self.timeEater.status.strength or 0
    lu.assertEquals(newStrength, initialStrength + 2)
end

function TestTimeEater:testReverberateAttack()
    -- Set up Time Eater to use Reverberate
    self.timeEater.currentIntent = {
        name = "Reverberate",
        execute = self.timeEater.intents.reverberate
    }

    local initialHp = self.player.hp

    -- Execute intent
    self.timeEater.executeIntent(self.timeEater, self.world, self.player)
    ProcessEventQueue.execute(self.world)

    -- Player should take 7×3 = 21 damage (modified by block/strength)
    -- Verify damage was dealt (exact amount depends on Time Eater's strength)
    lu.assertTrue(self.player.hp < initialHp or self.player.block > 0)
end

function TestTimeEater:testHeadSlamAttack()
    -- Set up Time Eater to use Head Slam
    self.timeEater.currentIntent = {
        name = "Head Slam",
        execute = self.timeEater.intents.head_slam
    }

    local initialHp = self.player.hp

    -- Execute intent
    self.timeEater.executeIntent(self.timeEater, self.world, self.player)
    ProcessEventQueue.execute(self.world)

    -- Player should have Draw Reduction
    lu.assertEquals(self.player.status.draw_reduction, 1)

    -- Player should take damage
    lu.assertTrue(self.player.hp < initialHp or self.player.block > 0)
end

function TestTimeEater:testRippleDefense()
    -- Set up Time Eater to use Ripple
    self.timeEater.currentIntent = {
        name = "Ripple",
        execute = self.timeEater.intents.ripple
    }

    -- Execute intent
    self.timeEater.executeIntent(self.timeEater, self.world, self.player)
    ProcessEventQueue.execute(self.world)

    -- Time Eater should gain 20 block
    lu.assertEquals(self.timeEater.block, 20)

    -- Player should have Vulnerable and Weak
    lu.assertEquals(self.player.status.vulnerable, 1)
    lu.assertEquals(self.player.status.weak, 1)
end

function TestTimeEater:testHasteAbility()
    -- Damage Time Eater below 50% HP
    self.timeEater.hp = math.floor(self.timeEater.maxHp / 2) - 10

    -- Apply some debuffs
    self.timeEater.status.weak = 2
    self.timeEater.status.vulnerable = 3
    self.timeEater.status.strength = -5

    -- Trigger selectIntent (should choose Haste)
    self.timeEater.selectIntent(self.timeEater, self.world, self.player)
    lu.assertEquals(self.timeEater.currentIntent.name, "Haste")

    -- Execute Haste
    self.timeEater.executeIntent(self.timeEater, self.world, self.player)
    ProcessEventQueue.execute(self.world)

    -- HP should be at 50%
    lu.assertEquals(self.timeEater.hp, math.floor(self.timeEater.maxHp / 2))

    -- Debuffs should be cleared
    lu.assertEquals(self.timeEater.status.weak, 0)
    lu.assertEquals(self.timeEater.status.vulnerable, 0)
    lu.assertEquals(self.timeEater.status.strength, 0) -- Negative strength removed
end

function TestTimeEater:testHasteOnlyUsedOnce()
    -- Damage Time Eater below 50% HP
    self.timeEater.hp = math.floor(self.timeEater.maxHp / 2) - 10

    -- First time should trigger Haste
    self.timeEater.selectIntent(self.timeEater, self.world, self.player)
    lu.assertEquals(self.timeEater.currentIntent.name, "Haste")

    -- Execute Haste
    self.timeEater.executeIntent(self.timeEater, self.world, self.player)
    ProcessEventQueue.execute(self.world)

    -- Damage again below 50%
    self.timeEater.hp = math.floor(self.timeEater.maxHp / 2) - 20

    -- Should NOT use Haste again
    self.timeEater.selectIntent(self.timeEater, self.world, self.player)
    lu.assertNotEquals(self.timeEater.currentIntent.name, "Haste")
end

os.exit(lu.LuaUnit.run())
