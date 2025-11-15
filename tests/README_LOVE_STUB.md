# LÖVE Stub - Testing GUI Mode Without LÖVE Engine

This directory contains a stub/mock implementation of the LÖVE 2D framework that allows testing the GUI mode (`main.lua`) without requiring the actual LÖVE engine to be installed.

## Files

- **`love-stub.lua`** - Complete mock of LÖVE framework APIs
- **`test_love_integration.lua`** - Integration tests for GUI mode
- **`README_LOVE_STUB.md`** - This file

## Usage

### Running the Integration Test

```bash
lua tests/test_love_integration.lua
```

This will:
1. Initialize the LÖVE stub
2. Load `main.lua` (the GUI entry point)
3. Run the game initialization (`love.load()`)
4. Execute 10 game loop frames
5. Test keyboard input simulation
6. Optionally track graphics calls

### Using the Stub in Your Own Tests

```lua
-- Load and initialize the stub
local LoveStub = require("tests.love-stub")
LoveStub.init()

-- Now the global 'love' table is available
require("main")  -- or any code using LÖVE

-- Run game loop frames
LoveStub.runFrames(10)

-- Simulate keyboard input
LoveStub.keypressed("down")
LoveStub.runFrames(1)
LoveStub.keyreleased("down")

-- Enable call tracking to see what "would be rendered"
LoveStub.enableCallTracking(true)
LoveStub.runFrames(1)
local calls = LoveStub.getTrackedCalls()
for _, call in ipairs(calls) do
    print(call.func, table.concat(call.args, ", "))
end
```

## Supported LÖVE APIs

The stub implements the following LÖVE modules and functions:

### love.window
- `setTitle(title)` - Set window title
- `setMode(width, height)` - Set window dimensions
- `getMode()` - Get window dimensions

### love.graphics
- `setColor(r, g, b, a)` - Set drawing color
- `setBackgroundColor(r, g, b, a)` - Set background color
- `clear()` - Clear screen
- `print(text, x, y, ...)` - Print text
- `printf(text, x, y, limit, align, ...)` - Print formatted text
- `rectangle(mode, x, y, w, h)` - Draw rectangle
- `circle(mode, x, y, radius)` - Draw circle
- `line(...)` - Draw line
- `polygon(mode, ...)` - Draw polygon
- `push()`, `pop()` - Matrix stack
- `translate(dx, dy)` - Translate transformation
- `scale(sx, sy)` - Scale transformation
- `rotate(angle)` - Rotate transformation
- `getDimensions()`, `getWidth()`, `getHeight()` - Get screen size

### love.keyboard
- `isDown(key)` - Check if key is pressed

### love.event
- `quit()` - Request quit

### love.timer
- `getDelta()` - Get delta time (simulated 60 FPS)
- `getFPS()` - Get frames per second

## Stub Control API

The stub provides additional functions for testing (not part of LÖVE):

- `LoveStub.init()` - Initialize stub (sets global `love`)
- `LoveStub.runFrames(count)` - Run N frames of game loop
- `LoveStub.keypressed(key)` - Simulate key press
- `LoveStub.keyreleased(key)` - Simulate key release
- `LoveStub.typeKey(key)` - Simulate key press + release
- `LoveStub.textinput(text)` - Simulate text input
- `LoveStub.enableCallTracking(bool)` - Enable/disable call tracking
- `LoveStub.getTrackedCalls()` - Get tracked graphics calls
- `LoveStub.clearTrackedCalls()` - Clear tracked calls
- `LoveStub.reset()` - Reset stub to initial state
- `LoveStub.shouldQuit()` - Check if quit was requested

## Benefits

✅ **Test GUI code without LÖVE** - Validate code structure and logic
✅ **CI/CD compatible** - No GUI required
✅ **Catch errors early** - Find null references and logic bugs
✅ **Debug graphics calls** - Optional tracking shows what would be rendered
✅ **Simulate input** - Test keyboard navigation and user interaction

## Limitations

❌ **No actual rendering** - Graphics calls are no-ops (but can be tracked)
❌ **No visual output** - Can't see what the game looks like
❌ **Limited API coverage** - Only implements commonly used LÖVE functions
❌ **No image/font loading** - Asset loading not supported

For full visual testing, use the actual LÖVE engine.

## Example Test Output

```
================================================================================
LÖVE Integration Test - GUI Mode Validation
================================================================================

[1/6] ✓ LÖVE stub initialized
[2/6] ✓ Global 'love' table verified
[3/6] ✓ main.lua loaded successfully
[4/6] ✓ LÖVE callbacks are set
[5/6] ✓ love.load() executed successfully
[6/6] ✓ 10 game frames executed without errors

[TRACKING] Testing optional call tracking...
✓ Call tracking works - captured 14 graphics calls
  Sample calls:
    - graphics.setColor(1, 1, 1)
    - graphics.print(KILL THE TOWER, 50, 50, 0, 2, 2)

================================================================================
ALL TESTS PASSED ✅
================================================================================
```

## Adding More LÖVE APIs

If you need additional LÖVE functions, add them to `love-stub.lua`:

```lua
-- In the appropriate module
function graphics.newFunction(...)
    trackCall("graphics.newFunction", ...)
    -- Your stub implementation
end
```

The `trackCall()` helper ensures the call is tracked if tracking is enabled.
