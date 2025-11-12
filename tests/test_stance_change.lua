-- Test for Stance Change System
--
-- This test verifies:
-- 1. Player can enter a stance from no stance
-- 2. Stance-specific effects execute on enter (e.g., Divinity gives energy)
-- 3. Stance-specific effects execute on exit (e.g., Calm gives energy)
-- 4. Player can change from one stance to another
-- 5. Both exit and enter flows are managed correctly

local World = require("World")
local ChangeStance = require("Pipelines.ChangeStance")

print("=== Test 1: Enter Wrath stance from no stance ===")

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

-- Verify player starts with no stance
assert(world1.player.currentStance == nil, "Player should start with no stance")

-- Change to Wrath stance
ChangeStance.execute(world1, {newStance = "Wrath"})

-- Verify stance was set
assert(world1.player.currentStance == "Wrath", "Player should now be in Wrath stance")
assert(#world1.log == 1, "Should have 1 log entry (enter)")
print("✓ Player entered Wrath stance successfully")

print("\n=== Test 2: Exit Calm stance and gain energy ===")

local world2 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {},
    relics = {}
})

world2.log = {}
world2.player.energy = 1

-- Set initial stance to Calm
world2.player.currentStance = "Calm"

-- Exit Calm stance (change to nil)
ChangeStance.execute(world2, {newStance = nil})

-- Verify stance was cleared and energy was gained
assert(world2.player.currentStance == nil, "Player should have no stance")
assert(world2.player.energy == 3, "Player should have gained 2 energy from Calm exit (1 + 2 = 3), got: " .. world2.player.energy)
assert(#world2.log == 2, "Should have 2 log entries (exit + neutral message)")
print("✓ Player exited Calm stance and gained 2 energy")

print("\n=== Test 3: Enter Divinity stance and gain energy ===")

local world3 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {},
    relics = {}
})

world3.log = {}
world3.player.energy = 0

-- Enter Divinity stance
ChangeStance.execute(world3, {newStance = "Divinity"})

-- Verify stance was set and energy was gained
assert(world3.player.currentStance == "Divinity", "Player should be in Divinity stance")
assert(world3.player.energy == 3, "Player should have gained 3 energy from Divinity enter, got: " .. world3.player.energy)
print("✓ Player entered Divinity stance and gained 3 energy")

print("\n=== Test 4: Change from Calm to Wrath ===")

local world4 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {},
    relics = {}
})

world4.log = {}
world4.player.energy = 1
world4.player.currentStance = "Calm"

-- Change from Calm to Wrath
ChangeStance.execute(world4, {newStance = "Wrath"})

-- Verify stance changed and Calm exit effect applied
assert(world4.player.currentStance == "Wrath", "Player should be in Wrath stance")
assert(world4.player.energy == 3, "Player should have gained 2 energy from Calm exit, got: " .. world4.player.energy)
assert(#world4.log == 2, "Should have 2 log entries (Calm exit + Wrath enter)")
print("✓ Player changed from Calm to Wrath")
print("✓ Exit and enter effects both executed")

print("\n=== Test 5: Change from Wrath to Divinity ===")

local world5 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {},
    relics = {}
})

world5.log = {}
world5.player.energy = 0
world5.player.currentStance = "Wrath"

-- Change from Wrath to Divinity
ChangeStance.execute(world5, {newStance = "Divinity"})

-- Verify stance changed and Divinity enter effect applied
assert(world5.player.currentStance == "Divinity", "Player should be in Divinity stance")
assert(world5.player.energy == 3, "Player should have gained 3 energy from Divinity enter, got: " .. world5.player.energy)
assert(#world5.log == 2, "Should have 2 log entries (Wrath exit + Divinity enter)")
print("✓ Player changed from Wrath to Divinity")
print("✓ Wrath exit had no effect, Divinity enter gave energy")

print("\n=== Test 6: Exit Divinity has no special effect ===")

local world6 = World.createWorld({
    id = "Watcher",
    maxHp = 72,
    hp = 72,
    maxEnergy = 3,
    deck = {},
    relics = {}
})

world6.log = {}
world6.player.energy = 0
world6.player.currentStance = "Divinity"

-- Exit Divinity
ChangeStance.execute(world6, {newStance = nil})

-- Verify Divinity exit had no energy effect
assert(world6.player.currentStance == nil, "Player should have no stance")
assert(world6.player.energy == 0, "Divinity exit should not give energy, got: " .. world6.player.energy)
print("✓ Divinity exit had no special effect")

print("\n=== All Stance Change Tests Passed! ===")
