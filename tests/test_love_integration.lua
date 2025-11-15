-- LÖVE Integration Test
-- Tests main.lua GUI mode using love-stub
--
-- Run with: lua tests/test_love_integration.lua

print(string.rep("=", 80))
print("LÖVE Integration Test - GUI Mode Validation")
print(string.rep("=", 80))

-- Initialize the stub
local LoveStub = require("tests.love-stub")
LoveStub.init()

print("\n[1/6] ✓ LÖVE stub initialized")

-- Verify global 'love' exists
assert(_G.love ~= nil, "Global 'love' should be set")
assert(_G.love.graphics ~= nil, "love.graphics should exist")
assert(_G.love.window ~= nil, "love.window should exist")
assert(_G.love.keyboard ~= nil, "love.keyboard should exist")

print("[2/6] ✓ Global 'love' table verified")

-- Load main.lua (this will set love.load, love.draw, etc.)
print("\n[3/6] Loading main.lua...")
local success, err = pcall(function()
    require("main")
end)

if not success then
    print("❌ FAILED to load main.lua:")
    print(err)
    os.exit(1)
end

print("[3/6] ✓ main.lua loaded successfully")

-- Verify callbacks were set
assert(type(love.load) == "function", "love.load should be a function")
assert(type(love.draw) == "function", "love.draw should be a function")
assert(type(love.update) == "function", "love.update should be a function")
assert(type(love.keypressed) == "function", "love.keypressed should be a function")

print("[4/6] ✓ LÖVE callbacks are set")

-- Test 1: Call love.load() to initialize
print("\n[5/6] Testing game initialization...")
local success, err = pcall(function()
    love.load()
end)

if not success then
    print("❌ FAILED during love.load():")
    print(err)
    os.exit(1)
end

print("[5/6] ✓ love.load() executed successfully")

-- Test 2: Run some frames to ensure no crashes
print("\n[6/6] Running 10 game frames...")
local success, err = pcall(function()
    LoveStub.runFrames(10)
end)

if not success then
    print("❌ FAILED during game loop:")
    print(err)
    os.exit(1)
end

print("[6/6] ✓ 10 game frames executed without errors")

-- Test 3: Test menu navigation
print("\n[TEST 3] Testing menu navigation...")

-- Simulate pressing 'down' arrow
local success, err = pcall(function()
    LoveStub.keypressed("down")
    LoveStub.runFrames(1)
    LoveStub.keyreleased("down")
end)

if not success then
    print("❌ FAILED: Down arrow navigation:")
    print(err)
    os.exit(1)
end
print("✓ Down arrow key handled successfully")

-- Simulate pressing 'up' arrow
local success, err = pcall(function()
    LoveStub.keypressed("up")
    LoveStub.runFrames(1)
    LoveStub.keyreleased("up")
end)

if not success then
    print("❌ FAILED: Up arrow navigation:")
    print(err)
    os.exit(1)
end
print("✓ Up arrow key handled successfully")

-- Test 4: Verify card data is loaded
print("\n[TEST 4] Verifying card data...")
local Cards = require("Data.cards")
local test_cards = {'Strike', 'Defend', 'Bash', 'FlameBarrier', 'Bloodletting'}
for _, name in ipairs(test_cards) do
    if not Cards[name] then
        print("❌ FAILED: Card missing:", name)
        os.exit(1)
    end
end
print("✓ All required cards exist")

-- Test 5: Try to start Combat Demo (menu option 1)
print("\n[TEST 5] Testing Combat Demo start...")

-- First ensure we're on option 1 (press up if needed)
LoveStub.keypressed("up")
LoveStub.runFrames(1)
LoveStub.keyreleased("up")

-- Press Enter to select "Start Combat"
local success, err = pcall(function()
    LoveStub.keypressed("return")
    LoveStub.runFrames(5)  -- Run a few frames to let combat initialize
    LoveStub.keyreleased("return")
end)

if not success then
    print("❌ FAILED: Combat Demo start:")
    print(err)
    print("\nThis error also occurs in the real LÖVE game!")

    -- Debug info
    print("\nDebug: Checking Cards table...")
    for _, name in ipairs(test_cards) do
        print("  Cards." .. name .. " = " .. tostring(Cards[name]))
    end
    os.exit(1)
end
print("✓ Combat Demo started successfully")

-- Test 6: Reset and try Map Demo (menu option 2)
print("\n[TEST 6] Testing Map Demo start...")

-- Reload to reset to menu
LoveStub.reset()
love.load()

-- Navigate to option 2 (down arrow)
LoveStub.keypressed("down")
LoveStub.runFrames(1)
LoveStub.keyreleased("down")

-- Press Enter to select "Start Map"
local success, err = pcall(function()
    LoveStub.keypressed("return")
    LoveStub.runFrames(5)  -- Run a few frames to let map initialize
    LoveStub.keyreleased("return")
end)

if not success then
    print("❌ FAILED: Map Demo start:")
    print(err)
    print("\nThis error also occurs in the real LÖVE game!")
    os.exit(1)
end
print("✓ Map Demo started successfully")

-- Test 7: Verify we can enable call tracking
print("\n[TRACKING] Testing optional call tracking...")
LoveStub.enableCallTracking(true)
LoveStub.runFrames(1)

local calls = LoveStub.getTrackedCalls()
if #calls > 0 then
    print("✓ Call tracking works - captured " .. #calls .. " graphics calls")
    print("  Sample calls:")
    for i = 1, math.min(5, #calls) do
        local call = calls[i]
        print(string.format("    - %s(%s)", call.func, table.concat(call.args or {}, ", ")))
    end
else
    print("⚠️  No graphics calls tracked (might be intentional)")
end

LoveStub.enableCallTracking(false)

-- Final summary
print("\n" .. string.rep("=", 80))
print("ALL TESTS PASSED ✅")
print(string.rep("=", 80))
print("\nSummary:")
print("  ✓ LÖVE stub initialization")
print("  ✓ main.lua loading")
print("  ✓ Game initialization (love.load)")
print("  ✓ Game loop execution (10 frames)")
print("  ✓ Keyboard input handling")
print("  ✓ Optional call tracking")
print("\nThe GUI mode structure is valid and can run without LÖVE engine!")
print(string.rep("=", 80))
