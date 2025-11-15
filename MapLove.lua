-- MAP LOVE2D DRIVER
-- Thin wrapper around MapEngine using LOVE 2D primitives

local MapLove = {}

local MapEngine = require("MapEngine")

-- UI State
local uiState = {
    mode = "navigation", -- "navigation", "options", "cards", "event"
    inputBuffer = "",
    logMessages = {},
    pendingSelection = nil,
    options = {},
    selectableCards = {},
    selectedCards = {},
    selectionBounds = {},
    availableNodes = {},
    currentNode = nil,
    active = false
}

-- Helper: Add log entry
local function addLog(message)
    table.insert(uiState.logMessages, message)
    if #uiState.logMessages > 15 then
        table.remove(uiState.logMessages, 1)
    end
end

-- ============================================================================
-- RENDERING
-- ============================================================================

local function drawCurrentNode(world, x, y)
    local node = MapEngine.getCurrentNode(world)
    if not node then
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("No current node", x, y)
        return y + 20
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("CURRENT LOCATION:", x, y)
    y = y + 25

    -- Node box
    local nodeColor = {0.3, 0.4, 0.6}
    if node.type == "combat" then
        nodeColor = {0.7, 0.2, 0.2}
    elseif node.type == "elite" then
        nodeColor = {0.8, 0.3, 0.1}
    elseif node.type == "rest" then
        nodeColor = {0.2, 0.6, 0.3}
    elseif node.type == "merchant" then
        nodeColor = {0.6, 0.5, 0.2}
    elseif node.type == "treasure" then
        nodeColor = {0.8, 0.7, 0.2}
    end

    love.graphics.setColor(nodeColor[1], nodeColor[2], nodeColor[3])
    love.graphics.rectangle("fill", x, y, 400, 50)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, 400, 50)

    love.graphics.setColor(1, 1, 1)
    local nodeText = string.format("Node: %s | Type: %s | Floor: %d",
        node.id or "?",
        (node.type or "unknown"):upper(),
        node.floor or 0
    )
    love.graphics.print(nodeText, x + 5, y + 5)

    if node.event then
        love.graphics.setColor(0.9, 0.8, 0.5)
        love.graphics.print("Event: " .. node.event, x + 5, y + 25)
    end

    return y + 60
end

local function drawAvailableNodes(world, x, y)
    local node = MapEngine.getCurrentNode(world)
    if not node or not node.connections or #node.connections == 0 then
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("No available paths", x, y)
        return y + 20
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("AVAILABLE PATHS:", x, y)
    y = y + 25

    for i, nodeId in ipairs(node.connections) do
        local target = world.map.nodes[nodeId]
        if target then
            local nodeType = (target.type or "unknown"):upper()
            local floor = target.floor or "?"

            -- Draw path option
            love.graphics.setColor(0.4, 0.5, 0.6)
            love.graphics.rectangle("fill", x, y, 400, 30)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", x, y, 400, 30)

            love.graphics.setColor(1, 1, 1)
            love.graphics.print(string.format("[%d] %s - %s (Floor %s)", i, nodeId, nodeType, floor), x + 5, y + 5)

            y = y + 35
        end
    end

    return y
end

local function drawPlayerStats(world, x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("PLAYER:", x, y)
    y = y + 25

    love.graphics.setColor(0.2, 0.4, 0.6)
    love.graphics.rectangle("fill", x, y, 350, 60)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, 350, 60)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("%s - HP: %d/%d",
        world.player.id,
        world.player.hp or world.player.currentHp,
        world.player.maxHp
    ), x + 5, y + 5)

    love.graphics.print(string.format("Gold: %d | Floor: %d",
        world.player.gold or 0,
        world.floor or 1
    ), x + 5, y + 25)

    if world.player.masterDeck then
        love.graphics.print(string.format("Deck: %d cards", #world.player.masterDeck), x + 5, y + 40)
    end

    return y + 70
end

local function drawLog(x, y)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("LOG:", x, y)
    y = y + 20

    love.graphics.setColor(0.7, 0.7, 0.7)
    for i = math.max(1, #uiState.logMessages - 8), #uiState.logMessages do
        if uiState.logMessages[i] then
            love.graphics.print(uiState.logMessages[i], x, y)
            y = y + 15
        end
    end

    return y
end

local function drawNavigationPrompt(x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("NAVIGATION:", x, y)
    y = y + 20

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Type a number to choose a path, or 'q' to quit", x, y)
    y = y + 20

    love.graphics.setColor(1, 1, 0)
    love.graphics.print("> " .. uiState.inputBuffer, x, y)

    return y
end

local function drawOptionsPrompt(x, y)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("Choose an option:", x, y)
    y = y + 20

    for i, option in ipairs(uiState.options) do
        love.graphics.setColor(0.9, 0.9, 0.9)
        local label = option.label or ("Option " .. i)
        local desc = option.description or ""
        if desc ~= "" then
            label = label .. " - " .. desc
        end
        love.graphics.print(string.format("[%d] %s", i, label), x, y)
        y = y + 15
    end

    y = y + 10
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("> " .. uiState.inputBuffer, x, y)

    return y
end

local function drawCardSelectPrompt(x, y)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("Select cards (type numbers, ENTER to confirm):", x, y)
    y = y + 20

    local bounds = uiState.selectionBounds
    local minSelect = bounds.min or 1
    local maxSelect = bounds.max or minSelect

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(string.format("Selected: %d (need %d-%d)", #uiState.selectedCards, minSelect, maxSelect), x, y)
    y = y + 20

    for i, card in ipairs(uiState.selectableCards) do
        local isSelected = false
        for _, selected in ipairs(uiState.selectedCards) do
            if selected == card then
                isSelected = true
                break
            end
        end

        if isSelected then
            love.graphics.setColor(0.3, 0.8, 0.3)
            love.graphics.print(string.format("[%d] * %s", i, card.name), x, y)
        else
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print(string.format("[%d]   %s", i, card.name), x, y)
        end
        y = y + 15
    end

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("[0] Skip (if optional) | [ENTER] Submit", x, y)
    y = y + 20

    love.graphics.setColor(1, 1, 0)
    love.graphics.print("> " .. uiState.inputBuffer, x, y)

    return y
end

function MapLove.draw(world)
    if not world then return end

    local x, y = 20, 20

    -- Draw player stats
    y = drawPlayerStats(world, x, y)
    y = y + 10

    -- Draw current node
    y = drawCurrentNode(world, x, y)
    y = y + 10

    -- Draw mode-specific UI
    if uiState.mode == "navigation" then
        y = drawAvailableNodes(world, x, y)
        y = y + 10
        y = drawNavigationPrompt(x, y)
    elseif uiState.mode == "options" then
        y = drawOptionsPrompt(x, y)
    elseif uiState.mode == "cards" then
        y = drawCardSelectPrompt(x, y)
    end

    -- Draw log
    drawLog(x, 600)

    -- Help text
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Press ESC to return to menu", 20, 740)
end

function MapLove.update(world, dt)
    -- Could add animations here later
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

function MapLove.textinput(world, text)
    if not uiState.active then return end
    uiState.inputBuffer = uiState.inputBuffer .. text
end

function MapLove.keypressed(world, key)
    if key == "escape" then
        if _G.returnToMenu then
            _G.returnToMenu()
        end
        return
    end

    if not uiState.active then return end

    if key == "backspace" then
        uiState.inputBuffer = uiState.inputBuffer:sub(1, -2)
    elseif key == "return" then
        processInput(world)
    end
end

function processInput(world)
    local input = uiState.inputBuffer:lower():gsub("^%s*(.-)%s*$", "%1")
    uiState.inputBuffer = ""

    if uiState.mode == "navigation" then
        handleNavigationInput(world, input)
    elseif uiState.mode == "options" then
        handleOptionsInput(world, input)
    elseif uiState.mode == "cards" then
        handleCardSelectInput(world, input)
    end
end

function handleNavigationInput(world, input)
    if input == "q" or input == "quit" then
        addLog("Exiting map...")
        uiState.active = false
        if _G.returnToMenu then
            _G.returnToMenu()
        end
        return
    end

    local choice = tonumber(input)
    local node = MapEngine.getCurrentNode(world)

    if node and node.connections and choice and choice >= 1 and choice <= #node.connections then
        uiState.pendingSelection = node.connections[choice]
        addLog("Moving to node: " .. uiState.pendingSelection)
    else
        addLog("Invalid choice. Try again.")
    end
end

function handleOptionsInput(world, input)
    local choice = tonumber(input)
    if choice and uiState.options[choice] then
        uiState.pendingSelection = uiState.options[choice]
        addLog("Selected: " .. (uiState.options[choice].label or "Option " .. choice))
        uiState.mode = "navigation"
    else
        addLog("Invalid option. Try again.")
    end
end

function handleCardSelectInput(world, input)
    local choice = tonumber(input)
    local bounds = uiState.selectionBounds
    local minSelect = bounds.min or 1
    local maxSelect = bounds.max or minSelect

    if choice == 0 and minSelect == 0 then
        -- Skip selection
        uiState.pendingSelection = {}
        uiState.mode = "navigation"
        addLog("Skipped card selection.")
    elseif choice and uiState.selectableCards[choice] then
        -- Toggle card
        local card = uiState.selectableCards[choice]
        local found = false

        for i, selected in ipairs(uiState.selectedCards) do
            if selected == card then
                table.remove(uiState.selectedCards, i)
                found = true
                addLog(card.name .. " deselected.")
                break
            end
        end

        if not found then
            if #uiState.selectedCards >= maxSelect then
                addLog("Maximum cards selected.")
            else
                table.insert(uiState.selectedCards, card)
                addLog(card.name .. " selected.")

                -- Auto-submit if we hit max
                if #uiState.selectedCards == maxSelect and maxSelect == minSelect then
                    uiState.pendingSelection = uiState.selectedCards
                    uiState.mode = "navigation"
                    addLog("Selection complete.")
                end
            end
        end
    else
        addLog("Invalid choice.")
    end
end

-- Override keypressed to handle ENTER specially for card selection
function MapLove.keypressed(world, key)
    if key == "escape" then
        if _G.returnToMenu then
            _G.returnToMenu()
        end
        return
    end

    if not uiState.active then return end

    if key == "backspace" then
        uiState.inputBuffer = uiState.inputBuffer:sub(1, -2)
    elseif key == "return" then
        if uiState.mode == "cards" and uiState.inputBuffer == "" then
            -- Submit card selection
            local bounds = uiState.selectionBounds
            local minSelect = bounds.min or 1
            if #uiState.selectedCards >= minSelect then
                uiState.pendingSelection = uiState.selectedCards
                uiState.mode = "navigation"
                addLog("Cards selected: " .. #uiState.selectedCards)
            else
                addLog(string.format("Need at least %d card(s).", minSelect))
            end
        else
            processInput(world)
        end
    end
end

-- ============================================================================
-- MAP ENGINE INTEGRATION
-- ============================================================================

local function promptOptionSelection(world, request)
    uiState.mode = "options"
    uiState.options = request.options or {}
    uiState.pendingSelection = nil

    if #uiState.options == 0 then
        addLog("No options available.")
        return nil
    end

    addLog(request.prompt or "Choose an option:")

    -- Wait for selection (in a real implementation, this would be event-driven)
    -- For now, return nil and handle via coroutines or callbacks
    return nil
end

local function promptCardSelection(world, request)
    uiState.mode = "cards"
    uiState.selectableCards = request.selectableCards or {}
    uiState.selectionBounds = request.selectionBounds or {min = 1, max = 1}
    uiState.selectedCards = {}
    uiState.pendingSelection = nil

    if #uiState.selectableCards == 0 then
        addLog("No cards available.")
        if uiState.selectionBounds.min == 0 then
            return {}
        end
        return nil
    end

    addLog("Select card(s) from the list.")

    return nil
end

function MapLove.init(world)
    -- Reset UI state
    uiState = {
        mode = "navigation",
        inputBuffer = "",
        logMessages = {},
        pendingSelection = nil,
        options = {},
        selectableCards = {},
        selectedCards = {},
        selectionBounds = {},
        availableNodes = {},
        currentNode = nil,
        active = true
    }

    addLog("Map exploration started!")
    addLog("Navigate through nodes to progress.")

    -- Set up event handlers
    world.mapEventOptions = {
        onOptionSelection = promptOptionSelection,
        onCardSelection = promptCardSelection
    }
end

return MapLove
