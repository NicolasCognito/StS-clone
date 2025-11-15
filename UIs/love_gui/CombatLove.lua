-- COMBAT LOVE2D DRIVER
-- Thin wrapper around CombatEngine using LOVE 2D primitives

local CombatLove = {}

local CombatEngine = require("CombatEngine")
local GetCost = require("Pipelines.GetCost")

-- UI State
local uiState = {
    mode = "action", -- "action", "target", "cardselect"
    inputBuffer = "",
    logMessages = {},
    contextRequest = nil,
    selectedCards = {},
    selectableCards = {},
    selectionBounds = {},
    livingEnemies = {},
    needsRender = true,
    gameActive = false,
    lastResult = nil
}

-- Helper: List living enemies
local function listLivingEnemies(world)
    local enemies = {}
    if not world.enemies then
        return enemies
    end
    for _, enemy in ipairs(world.enemies) do
        if enemy.hp > 0 then
            table.insert(enemies, enemy)
        end
    end
    return enemies
end

-- Helper: Add log entry
local function addLog(message)
    table.insert(uiState.logMessages, message)
    if #uiState.logMessages > 10 then
        table.remove(uiState.logMessages, 1)
    end
end

-- ============================================================================
-- RENDERING
-- ============================================================================

local function drawEnemies(world, x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("ENEMIES:", x, y)
    y = y + 25

    if not world.enemies or #world.enemies == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("(no enemies)", x + 10, y)
        return y + 20
    end

    for i, enemy in ipairs(world.enemies) do
        if enemy.hp > 0 then
            -- Draw enemy box
            love.graphics.setColor(0.7, 0.2, 0.2)
            love.graphics.rectangle("fill", x, y, 300, 40)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", x, y, 300, 40)

            -- Enemy info
            love.graphics.setColor(1, 1, 1)
            local text = string.format("[%d] %s - HP: %d/%d", i, enemy.name, enemy.hp, enemy.maxHp)
            love.graphics.print(text, x + 5, y + 5)

            -- Status effects
            local statusText = ""
            if enemy.status then
                if enemy.status.vulnerable and enemy.status.vulnerable > 0 then
                    statusText = statusText .. " Vuln:" .. enemy.status.vulnerable
                end
                if enemy.status.weak and enemy.status.weak > 0 then
                    statusText = statusText .. " Weak:" .. enemy.status.weak
                end
            end
            if statusText ~= "" then
                love.graphics.setColor(0.9, 0.7, 0.3)
                love.graphics.print(statusText, x + 5, y + 20)
            end

            y = y + 45
        else
            -- Dead enemy
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", x, y, 300, 30)
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.print(string.format("[%d] %s (DEAD)", i, enemy.name), x + 5, y + 5)
            y = y + 35
        end
    end

    return y
end

local function drawPlayer(world, x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("PLAYER:", x, y)
    y = y + 25

    -- Player box
    love.graphics.setColor(0.2, 0.3, 0.7)
    love.graphics.rectangle("fill", x, y, 400, 60)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, 400, 60)

    -- Player stats
    love.graphics.setColor(1, 1, 1)
    local hpText = string.format("%s - HP: %d/%d", world.player.id, world.player.hp, world.player.maxHp)
    love.graphics.print(hpText, x + 5, y + 5)

    local energyText = string.format("Energy: %d/%d", world.player.energy, world.player.maxEnergy)
    if world.player.block > 0 then
        energyText = energyText .. string.format(" | Block: %d", world.player.block)
    end
    love.graphics.print(energyText, x + 5, y + 25)

    -- Status effects
    local statusText = ""
    if world.player.status then
        if world.player.status.vulnerable and world.player.status.vulnerable > 0 then
            statusText = statusText .. " Vuln:" .. world.player.status.vulnerable
        end
        if world.player.status.weak and world.player.status.weak > 0 then
            statusText = statusText .. " Weak:" .. world.player.status.weak
        end
        if world.player.status.thorns and world.player.status.thorns > 0 then
            statusText = statusText .. " Thorns:" .. world.player.status.thorns
        end
    end
    if statusText ~= "" then
        love.graphics.setColor(0.9, 0.7, 0.3)
        love.graphics.print(statusText, x + 5, y + 45)
    end

    return y + 70
end

local function drawHand(world, x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HAND:", x, y)
    y = y + 25

    local hand = CombatEngine.getCardsByState(world.player, "HAND")
    if #hand == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("(empty)", x + 10, y)
        return y + 20
    end

    local cardWidth = 140
    local cardHeight = 80
    local spacing = 10

    for i, card in ipairs(hand) do
        local cardX = x + ((i - 1) % 6) * (cardWidth + spacing)
        local cardY = y + math.floor((i - 1) / 6) * (cardHeight + spacing)

        -- Card background
        love.graphics.setColor(0.2, 0.6, 0.3)
        love.graphics.rectangle("fill", cardX, cardY, cardWidth, cardHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", cardX, cardY, cardWidth, cardHeight)

        -- Card number
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("[" .. i .. "]", cardX + 5, cardY + 5)

        -- Card name
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(card.name, cardX + 5, cardY + 25)

        -- Card cost
        local cardCost = GetCost.execute(world, world.player, card)
        love.graphics.setColor(0.7, 0.9, 1)
        love.graphics.print("Cost: " .. cardCost, cardX + 5, cardY + 45)

        -- Type indicator
        love.graphics.setColor(0.8, 0.8, 0.8)
        local typeText = card.cardType or "?"
        love.graphics.print(typeText, cardX + 5, cardY + 60, 0, 0.7, 0.7)
    end

    return y + math.ceil(#hand / 6) * (cardHeight + spacing) + 10
end

local function drawLog(x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LOG:", x, y)
    y = y + 20

    love.graphics.setColor(0.8, 0.8, 0.8)
    for i = math.max(1, #uiState.logMessages - 4), #uiState.logMessages do
        if uiState.logMessages[i] then
            love.graphics.print(uiState.logMessages[i], x, y)
            y = y + 15
        end
    end

    return y
end

local function drawActionPrompt(x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("ACTIONS:", x, y)
    y = y + 20

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("Type: 'play <number>' to play a card", x, y)
    y = y + 15
    love.graphics.print("Type: 'end' to end turn", x, y)
    y = y + 15
    love.graphics.print("Press ESC to quit to menu", x, y)
    y = y + 20

    love.graphics.setColor(1, 1, 0)
    love.graphics.print("> " .. uiState.inputBuffer, x, y)

    return y
end

local function drawTargetPrompt(x, y)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("Choose a target (type number):", x, y)
    y = y + 20

    for i, enemy in ipairs(uiState.livingEnemies) do
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print(string.format("[%d] %s (%d HP)", i, enemy.name, enemy.hp), x, y)
        y = y + 15
    end

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("[0] Cancel", x, y)
    y = y + 20

    love.graphics.setColor(1, 1, 0)
    love.graphics.print("> " .. uiState.inputBuffer, x, y)

    return y
end

local function drawCardSelectPrompt(x, y)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("Select cards (toggle with numbers, press ENTER to confirm):", x, y)
    y = y + 20

    local bounds = uiState.selectionBounds
    local minSelect = bounds.min or 1
    local maxSelect = bounds.max or 1

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(string.format("Selected: %d/%d (need %d-%d)", #uiState.selectedCards, maxSelect, minSelect, maxSelect), x, y)
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
    love.graphics.print("[0] Cancel | [ENTER] Submit", x, y)
    y = y + 20

    love.graphics.setColor(1, 1, 0)
    love.graphics.print("> " .. uiState.inputBuffer, x, y)

    return y
end

function CombatLove.draw(world)
    if not world then return end

    local x, y = 20, 20

    -- Draw game state
    y = drawEnemies(world, x, y)
    y = y + 10
    y = drawPlayer(world, x, y)
    y = y + 10
    y = drawHand(world, x, y)
    y = y + 10

    -- Draw appropriate prompt based on mode
    if uiState.mode == "action" then
        y = drawActionPrompt(x, y + 10)
    elseif uiState.mode == "target" then
        y = drawTargetPrompt(x, y + 10)
    elseif uiState.mode == "cardselect" then
        y = drawCardSelectPrompt(x, y + 10)
    end

    -- Draw log at bottom
    drawLog(x, 680)

    -- Show result if game is over
    if not uiState.gameActive and uiState.lastResult then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 200, 300, 600, 150)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 200, 300, 600, 150)

        if uiState.lastResult == "victory" then
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.print("VICTORY!", 400, 330, 0, 2, 2)
        elseif uiState.lastResult == "defeat" then
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.print("DEFEAT!", 400, 330, 0, 2, 2)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("Combat Ended", 380, 330, 0, 1.5, 1.5)
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Press ESC to return to menu", 340, 400)
    end
end

function CombatLove.update(world, dt)
    -- Could add animations here later
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

function CombatLove.textinput(world, text)
    if not uiState.gameActive then return end
    uiState.inputBuffer = uiState.inputBuffer .. text
end

function CombatLove.keypressed(world, key)
    if key == "escape" then
        if _G.returnToMenu then
            _G.returnToMenu()
        end
        return
    end

    if not uiState.gameActive then return end

    if key == "backspace" then
        uiState.inputBuffer = uiState.inputBuffer:sub(1, -2)
    elseif key == "return" then
        processInput(world)
    end
end

function processInput(world)
    local input = uiState.inputBuffer:lower():gsub("^%s*(.-)%s*$", "%1")
    uiState.inputBuffer = ""

    if uiState.mode == "action" then
        handleActionInput(world, input)
    elseif uiState.mode == "target" then
        handleTargetInput(world, input)
    elseif uiState.mode == "cardselect" then
        handleCardSelectInput(world, input)
    end
end

function handleActionInput(world, input)
    local command, arg = input:match("^(%S+)%s*(%S*)$")
    command = command or input

    if command == "play" then
        local index = tonumber(arg)
        if not index then
            addLog("Please provide a card number to play.")
        else
            uiState.pendingAction = {type = "play", cardIndex = index}
        end
    elseif command == "end" then
        uiState.pendingAction = {type = "end"}
    else
        addLog("Unknown command. Type 'play <number>' or 'end'.")
    end
end

function handleTargetInput(world, input)
    local choice = tonumber(input)
    if choice == 0 then
        addLog("Cancelled.")
        uiState.pendingContext = nil
        uiState.pendingContextStatus = "cancel"
        uiState.mode = "action"
    elseif choice and uiState.livingEnemies[choice] then
        uiState.pendingContext = uiState.livingEnemies[choice]
        uiState.pendingContextStatus = "ok"
        uiState.mode = "action"
    else
        addLog("Invalid target. Try again.")
    end
end

function handleCardSelectInput(world, input)
    local choice = tonumber(input)
    local bounds = uiState.selectionBounds
    local minSelect = bounds.min or 1
    local maxSelect = bounds.max or 1

    if choice == 0 then
        addLog("Cancelled.")
        uiState.pendingContext = nil
        uiState.pendingContextStatus = "cancel"
        uiState.mode = "action"
    elseif choice and uiState.selectableCards[choice] then
        -- Toggle selection
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
                addLog("Already at maximum selection.")
            else
                table.insert(uiState.selectedCards, card)
                addLog(card.name .. " selected.")
            end
        end
    else
        addLog("Invalid selection.")
    end
end

-- Special handling for ENTER in card select mode
function CombatLove.keypressed(world, key)
    if key == "escape" then
        if _G.returnToMenu then
            _G.returnToMenu()
        end
        return
    end

    if not uiState.gameActive then return end

    if key == "backspace" then
        uiState.inputBuffer = uiState.inputBuffer:sub(1, -2)
    elseif key == "return" then
        if uiState.mode == "cardselect" and uiState.inputBuffer == "" then
            -- Submit selection
            local bounds = uiState.selectionBounds
            local minSelect = bounds.min or 1
            if #uiState.selectedCards >= minSelect then
                uiState.pendingContext = uiState.selectedCards
                uiState.pendingContextStatus = "ok"
                uiState.mode = "action"
                addLog("Selection submitted.")
            else
                addLog(string.format("Need at least %d card(s).", minSelect))
            end
        else
            processInput(world)
        end
    end
end

-- ============================================================================
-- ENGINE INTEGRATION
-- ============================================================================

local function onRenderState(world)
    -- Just set a flag; actual rendering happens in draw()
    uiState.needsRender = true
end

local function onContextRequest(world, request)
    local contextType = (request.contextProvider and request.contextProvider.type) or "none"

    if contextType == "enemy" then
        uiState.mode = "target"
        uiState.livingEnemies = listLivingEnemies(world)
        uiState.pendingContext = nil
        uiState.pendingContextStatus = nil

        -- Wait for input
        while uiState.pendingContextStatus == nil and uiState.gameActive do
            coroutine.yield()
        end

        return uiState.pendingContext, uiState.pendingContextStatus or "cancel"
    elseif contextType == "cards" then
        uiState.mode = "cardselect"
        uiState.selectableCards = request.selectableCards or {}
        uiState.selectionBounds = request.selectionBounds or {min = 1, max = 1}
        uiState.selectedCards = {}
        uiState.pendingContext = nil
        uiState.pendingContextStatus = nil

        -- Wait for input
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

    -- Wait for player input
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
    CombatEngine.displayLog(world, count)
    -- Copy last messages to UI log
    if world.log then
        local start = math.max(1, #world.log - (count or 5) + 1)
        for i = start, #world.log do
            addLog(world.log[i])
        end
    end
end

local function onCombatResult(world, result)
    uiState.lastResult = result
    if result == "victory" then
        addLog("VICTORY! You defeated all enemies!")
    elseif result == "defeat" then
        addLog("DEFEAT! You were slain!")
    end
end

local function onCombatEnd(world, result)
    uiState.gameActive = false
    addLog("Combat ended: " .. tostring(result))
end

function CombatLove.init(world)
    -- Reset UI state
    uiState = {
        mode = "action",
        inputBuffer = "",
        logMessages = {},
        contextRequest = nil,
        selectedCards = {},
        selectableCards = {},
        selectionBounds = {},
        livingEnemies = {},
        needsRender = true,
        gameActive = true,
        lastResult = nil
    }

    addLog("Combat started!")

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

function CombatLove.update(world, dt)
    -- Resume combat coroutine if it's waiting
    if uiState.combatCoroutine and coroutine.status(uiState.combatCoroutine) ~= "dead" then
        coroutine.resume(uiState.combatCoroutine)
    end
end

return CombatLove
