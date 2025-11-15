-- COMBAT LOVE2D DRIVER (Remade)
-- Mouse-driven GUI for combat using StS-style layout

local CombatLove = {}

local CombatEngine = require("CombatEngine")
local CombatRenderer = require("UIs.love_gui.CombatRenderer")
local CombatInput = require("UIs.love_gui.CombatInput")

-- ============================================================================
-- UI STATE
-- ============================================================================

local uiState = {
    mode = "action",              -- "action", "target", "cardselect"
    gameActive = false,
    lastResult = nil,

    -- Pending actions/contexts
    pendingAction = nil,
    pendingContext = nil,
    pendingContextStatus = nil,

    -- Hover tracking
    hoveredCardIndex = nil,
    hoveredEnemyIndex = nil,
    hoveredEndTurnButton = false,

    -- Card selection popup state
    cardSelectionState = nil,     -- {selectableCards, selectedIndices, bounds, hoveredCardIndex, hoveredButton}

    -- Combat coroutine
    combatCoroutine = nil
}

-- ============================================================================
-- COMBAT ENGINE CALLBACKS
-- ============================================================================

local function onRenderState(world)
    -- Rendering happens in draw(), just set a flag if needed
end

local function onContextRequest(world, request)
    local contextType = (request.contextProvider and request.contextProvider.type) or "none"

    if contextType == "enemy" then
        uiState.mode = "target"
        uiState.pendingContext = nil
        uiState.pendingContextStatus = nil

        -- Wait for player to click an enemy
        while uiState.pendingContextStatus == nil and uiState.gameActive do
            coroutine.yield()
        end

        return uiState.pendingContext, uiState.pendingContextStatus or "cancel"

    elseif contextType == "cards" then
        uiState.mode = "cardselect"
        uiState.cardSelectionState = {
            selectableCards = request.selectableCards or {},
            selectedIndices = {},
            bounds = request.selectionBounds or {min = 1, max = 1},
            hoveredCardIndex = nil,
            hoveredButton = nil
        }
        uiState.pendingContext = nil
        uiState.pendingContextStatus = nil

        -- Wait for player to submit selection
        while uiState.pendingContextStatus == nil and uiState.gameActive do
            coroutine.yield()
        end

        return uiState.pendingContext, uiState.pendingContextStatus or "cancel"
    end

    return nil, "cancel"
end

local function onPlayerAction(world)
    uiState.mode = "action"
    uiState.pendingAction = nil

    -- Wait for player to click a card or end turn
    while uiState.pendingAction == nil and uiState.gameActive do
        coroutine.yield()
    end

    local action = uiState.pendingAction
    uiState.pendingAction = nil

    if action and action.type == "quit" then
        return nil, "quit"
    end

    return action, "ok"
end

local function onDisplayLog(world, count)
    -- Log display could be added later
end

local function onCombatResult(world, result)
    uiState.lastResult = result
end

local function onCombatEnd(world, result)
    uiState.gameActive = false
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function CombatLove.init(world)
    -- Reset UI state
    uiState = {
        mode = "action",
        gameActive = true,
        lastResult = nil,
        pendingAction = nil,
        pendingContext = nil,
        pendingContextStatus = nil,
        hoveredCardIndex = nil,
        hoveredEnemyIndex = nil,
        hoveredEndTurnButton = false,
        cardSelectionState = nil,
        combatCoroutine = nil
    }

    -- Create coroutine for combat loop
    uiState.combatCoroutine = coroutine.create(function()
        CombatEngine.playGame(world, {
            onRenderState = onRenderState,
            onContextRequest = onContextRequest,
            onPlayerAction = onPlayerAction,
            onDisplayLog = onDisplayLog,
            onCombatResult = onCombatResult,
            onCombatEnd = onCombatEnd
        })
    end)

    -- Start the combat coroutine
    coroutine.resume(uiState.combatCoroutine)
end

function CombatLove.draw(world)
    if not world then return end
    CombatRenderer.draw(world, uiState)
end

function CombatLove.update(world, dt)
    -- Update hover states
    CombatInput.updateHover(uiState, world)

    -- Resume combat coroutine if it's waiting
    if uiState.combatCoroutine and coroutine.status(uiState.combatCoroutine) ~= "dead" then
        coroutine.resume(uiState.combatCoroutine)
    end
end

function CombatLove.mousepressed(world, x, y, button)
    CombatInput.mousepressed(uiState, world, x, y, button)
end

function CombatLove.keypressed(world, key)
    if key == "escape" then
        if _G.returnToMenu then
            _G.returnToMenu()
        end
        return
    end
end

-- Unused but kept for compatibility
function CombatLove.textinput(world, text)
    -- Not needed for mouse-driven interface
end

return CombatLove
