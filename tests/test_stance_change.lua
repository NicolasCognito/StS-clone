-- Test for Stance Change System
--
-- This test verifies:
-- 1. Player can enter a stance from no stance
-- 2. onEnter callback is executed when entering a stance
-- 3. onExit callback is executed when exiting a stance
-- 4. Player can change from one stance to another
-- 5. Both exit and enter flows are managed correctly

local World = require("World")
local ChangeStance = require("Pipelines.ChangeStance")

print("=== Test 1: Enter stance from no stance ===")

local world1 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {},
    relics = {}
})

-- Initialize combat log
world1.log = {}

-- Create a test stance with enter callback
local enterCallbackCalled = false
local wrathStance = {
    name = "Wrath",
    onEnter = function(world, player)
        enterCallbackCalled = true
        -- In real implementation, Wrath might modify damage dealt/taken
    end
}

-- Verify player starts with no stance
assert(world1.player.currentStance == nil, "Player should start with no stance")

-- Change to Wrath stance
ChangeStance.execute(world1, {newStance = wrathStance})

-- Verify stance was set and callback was called
assert(world1.player.currentStance == wrathStance, "Player should now be in Wrath stance")
assert(enterCallbackCalled == true, "onEnter callback should have been called")
assert(#world1.log == 2, "Should have 2 log entries (enter + stance set)")
print("✓ Player entered Wrath stance successfully")
print("✓ onEnter callback was executed")

print("\n=== Test 2: Exit stance to no stance ===")

local world2 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {},
    relics = {}
})

world2.log = {}

-- Create a stance with exit callback
local exitCallbackCalled = false
local calmStance = {
    name = "Calm",
    onExit = function(world, player)
        exitCallbackCalled = true
        -- In real implementation, Calm might give energy when exiting
    end
}

-- Set initial stance
world2.player.currentStance = calmStance

-- Exit stance (change to nil)
ChangeStance.execute(world2, {newStance = nil})

-- Verify stance was cleared and callback was called
assert(world2.player.currentStance == nil, "Player should have no stance")
assert(exitCallbackCalled == true, "onExit callback should have been called")
assert(#world2.log == 2, "Should have 2 log entries (exit + no new stance message)")
print("✓ Player exited Calm stance successfully")
print("✓ onExit callback was executed")

print("\n=== Test 3: Change from one stance to another ===")

local world3 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {},
    relics = {}
})

world3.log = {}

-- Create two stances with both enter and exit callbacks
local oldExitCalled = false
local newEnterCalled = false

local divinityStance = {
    name = "Divinity",
    onEnter = function(world, player)
        -- Divinity gives triple energy
    end,
    onExit = function(world, player)
        oldExitCalled = true
        -- Divinity ends
    end
}

local neutralStance = {
    name = "Neutral",
    onEnter = function(world, player)
        newEnterCalled = true
        -- Neutral is default stance
    end,
    onExit = function(world, player)
        -- Nothing special
    end
}

-- Set initial stance
world3.player.currentStance = divinityStance

-- Change to new stance
ChangeStance.execute(world3, {newStance = neutralStance})

-- Verify both callbacks were called in correct order
assert(world3.player.currentStance == neutralStance, "Player should be in Neutral stance")
assert(oldExitCalled == true, "Old stance onExit should have been called")
assert(newEnterCalled == true, "New stance onEnter should have been called")
assert(#world3.log == 3, "Should have 3 log entries (exit + enter + stance set)")
print("✓ Player changed from Divinity to Neutral stance")
print("✓ Both onExit and onEnter callbacks were executed in correct order")

print("\n=== Test 4: Stance without callbacks ===")

local world4 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {},
    relics = {}
})

world4.log = {}

-- Create stances without callbacks
local simpleStance1 = {
    name = "SimpleStance1"
    -- No onEnter or onExit
}

local simpleStance2 = {
    name = "SimpleStance2"
    -- No onEnter or onExit
}

-- Change to first stance
ChangeStance.execute(world4, {newStance = simpleStance1})
assert(world4.player.currentStance == simpleStance1, "Should be in SimpleStance1")
print("✓ Entered stance without onEnter callback")

-- Change to second stance
ChangeStance.execute(world4, {newStance = simpleStance2})
assert(world4.player.currentStance == simpleStance2, "Should be in SimpleStance2")
print("✓ Changed stance when neither has callbacks")

print("\n=== Test 5: Verify callback execution order ===")

local world5 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {},
    relics = {}
})

world5.log = {}

local executionOrder = {}

local orderStance1 = {
    name = "OrderTest1",
    onExit = function(world, player)
        table.insert(executionOrder, "exit1")
    end
}

local orderStance2 = {
    name = "OrderTest2",
    onEnter = function(world, player)
        table.insert(executionOrder, "enter2")
    end
}

world5.player.currentStance = orderStance1

-- Change stance and verify order
ChangeStance.execute(world5, {newStance = orderStance2})

assert(#executionOrder == 2, "Should have 2 callbacks executed")
assert(executionOrder[1] == "exit1", "Exit should be called first")
assert(executionOrder[2] == "enter2", "Enter should be called second")
print("✓ Callbacks executed in correct order: exit then enter")

print("\n=== All Stance Change Tests Passed! ===")
