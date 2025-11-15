-- LÖVE 2D Framework Stub
-- Mock implementation of LÖVE framework for testing without the actual engine
-- Supports basic window, graphics, keyboard, and event APIs
--
-- Usage:
--   local Love = require("tests.love-stub")
--   Love.init()  -- Sets global 'love' table
--   -- Now load code that uses 'love' global
--   require("main")
--   -- Simulate game loop
--   Love.runFrames(10)
--   -- Simulate input
--   Love.keypressed("down")

local LoveStub = {}

-- Internal state
local state = {
    window = {
        title = "",
        width = 800,
        height = 600
    },
    keyboard = {
        keysDown = {}  -- Track which keys are pressed
    },
    graphics = {
        color = {1, 1, 1, 1},
        backgroundColor = {0, 0, 0, 1}
    },
    event = {
        shouldQuit = false
    },
    deltaTime = 1/60,  -- Simulate 60 FPS
    totalTime = 0
}

-- Call tracking (optional, disabled by default)
local callTracking = {
    enabled = false,
    calls = {}
}

-- Helper to track calls (no-op if disabled)
local function trackCall(funcName, ...)
    if callTracking.enabled then
        table.insert(callTracking.calls, {
            func = funcName,
            args = {...},
            time = state.totalTime
        })
    end
end

-----------------------------------------------------------
-- love.window module
-----------------------------------------------------------
local window = {}

function window.setTitle(title)
    state.window.title = title
    trackCall("window.setTitle", title)
end

function window.setMode(width, height, flags)
    state.window.width = width
    state.window.height = height
    trackCall("window.setMode", width, height, flags)
    return true
end

function window.getMode()
    return state.window.width, state.window.height
end

-----------------------------------------------------------
-- love.graphics module
-----------------------------------------------------------
local graphics = {}

function graphics.setColor(r, g, b, a)
    state.graphics.color = {r, g, b, a or 1}
    trackCall("graphics.setColor", r, g, b, a)
end

function graphics.setBackgroundColor(r, g, b, a)
    state.graphics.backgroundColor = {r, g, b, a or 1}
    trackCall("graphics.setBackgroundColor", r, g, b, a)
end

function graphics.clear(r, g, b, a)
    trackCall("graphics.clear", r, g, b, a)
    -- No-op in stub
end

function graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
    trackCall("graphics.print", text, x, y, r, sx, sy, ox, oy, kx, ky)
    -- No-op in stub
end

function graphics.printf(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
    trackCall("graphics.printf", text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
    -- No-op in stub
end

function graphics.rectangle(mode, x, y, width, height, rx, ry, segments)
    trackCall("graphics.rectangle", mode, x, y, width, height, rx, ry, segments)
    -- No-op in stub
end

function graphics.circle(mode, x, y, radius, segments)
    trackCall("graphics.circle", mode, x, y, radius, segments)
    -- No-op in stub
end

function graphics.line(...)
    trackCall("graphics.line", ...)
    -- No-op in stub
end

function graphics.points(...)
    trackCall("graphics.points", ...)
    -- No-op in stub
end

function graphics.polygon(mode, ...)
    trackCall("graphics.polygon", mode, ...)
    -- No-op in stub
end

function graphics.push(stackType)
    trackCall("graphics.push", stackType)
    -- No-op in stub
end

function graphics.pop()
    trackCall("graphics.pop")
    -- No-op in stub
end

function graphics.translate(dx, dy)
    trackCall("graphics.translate", dx, dy)
    -- No-op in stub
end

function graphics.scale(sx, sy)
    trackCall("graphics.scale", sx, sy or sx)
    -- No-op in stub
end

function graphics.rotate(angle)
    trackCall("graphics.rotate", angle)
    -- No-op in stub
end

function graphics.getDimensions()
    return state.window.width, state.window.height
end

function graphics.getWidth()
    return state.window.width
end

function graphics.getHeight()
    return state.window.height
end

-----------------------------------------------------------
-- love.keyboard module
-----------------------------------------------------------
local keyboard = {}

function keyboard.isDown(key)
    return state.keyboard.keysDown[key] == true
end

function keyboard.setKeyRepeat(enable)
    trackCall("keyboard.setKeyRepeat", enable)
    -- No-op in stub
end

-----------------------------------------------------------
-- love.event module
-----------------------------------------------------------
local event = {}

function event.quit()
    state.event.shouldQuit = true
    trackCall("event.quit")
end

-----------------------------------------------------------
-- love.timer module
-----------------------------------------------------------
local timer = {}

function timer.getDelta()
    return state.deltaTime
end

function timer.getFPS()
    return 60  -- Simulated 60 FPS
end

-----------------------------------------------------------
-- Main love table
-----------------------------------------------------------
local love = {
    window = window,
    graphics = graphics,
    keyboard = keyboard,
    event = event,
    timer = timer,

    -- Callbacks (will be overridden by main.lua)
    load = function() end,
    update = function(dt) end,
    draw = function() end,
    keypressed = function(key) end,
    keyreleased = function(key) end,
    textinput = function(text) end
}

-----------------------------------------------------------
-- Stub Control API (not part of LÖVE)
-----------------------------------------------------------

-- Initialize the stub (sets global 'love')
function LoveStub.init()
    _G.love = love

    -- Reset state
    state.keyboard.keysDown = {}
    state.event.shouldQuit = false
    state.totalTime = 0
    callTracking.calls = {}
end

-- Run N frames of the game loop
function LoveStub.runFrames(count)
    for i = 1, count do
        if state.event.shouldQuit then
            break
        end

        -- Call update with error handling
        if love.update then
            local success, err = pcall(love.update, state.deltaTime)
            if not success then
                error("Frame " .. i .. " update callback failed:\n" .. tostring(err), 2)
            end
        end

        -- Call draw with error handling
        if love.draw then
            local success, err = pcall(love.draw)
            if not success then
                error("Frame " .. i .. " draw callback failed:\n" .. tostring(err), 2)
            end
        end

        state.totalTime = state.totalTime + state.deltaTime
    end
end

-- Simulate a key press
function LoveStub.keypressed(key, scancode, isrepeat)
    state.keyboard.keysDown[key] = true

    if love.keypressed then
        love.keypressed(key, scancode, isrepeat or false)
    end
end

-- Simulate a key release
function LoveStub.keyreleased(key, scancode)
    state.keyboard.keysDown[key] = false

    if love.keyreleased then
        love.keyreleased(key, scancode)
    end
end

-- Simulate text input
function LoveStub.textinput(text)
    if love.textinput then
        love.textinput(text)
    end
end

-- Simulate key press + release
function LoveStub.typeKey(key, scancode)
    LoveStub.keypressed(key, scancode, false)
    LoveStub.keyreleased(key, scancode)
end

-- Enable/disable call tracking
function LoveStub.enableCallTracking(enable)
    callTracking.enabled = enable
    if enable then
        callTracking.calls = {}
    end
end

-- Get tracked calls
function LoveStub.getTrackedCalls()
    return callTracking.calls
end

-- Clear tracked calls
function LoveStub.clearTrackedCalls()
    callTracking.calls = {}
end

-- Get internal state (for assertions)
function LoveStub.getState()
    return state
end

-- Reset to initial state
function LoveStub.reset()
    state.keyboard.keysDown = {}
    state.event.shouldQuit = false
    state.totalTime = 0
    state.graphics.color = {1, 1, 1, 1}
    state.graphics.backgroundColor = {0, 0, 0, 1}
    callTracking.calls = {}
end

-- Check if quit was requested
function LoveStub.shouldQuit()
    return state.event.shouldQuit
end

return LoveStub
