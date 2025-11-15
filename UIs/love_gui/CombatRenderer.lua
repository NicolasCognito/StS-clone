-- COMBAT RENDERER
-- Handles all drawing for combat

local CombatRenderer = {}
local CombatUI = require("UIs.love_gui.CombatUI")
local CombatEngine = require("CombatEngine")
local GetCost = require("Pipelines.GetCost")

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function drawBox(box, fillColor, lineColor)
    if fillColor then
        love.graphics.setColor(fillColor)
        love.graphics.rectangle("fill", box.x, box.y, box.width, box.height)
    end
    if lineColor then
        love.graphics.setColor(lineColor)
        love.graphics.rectangle("line", box.x, box.y, box.width, box.height)
    end
end

local function drawText(text, x, y, color, scale)
    color = color or {1, 1, 1}
    scale = scale or 1
    love.graphics.setColor(color)
    love.graphics.print(text, x, y, 0, scale, scale)
end

local function drawButton(button, hovered)
    local fillColor = hovered and {0.3, 0.6, 0.3} or {0.2, 0.5, 0.2}
    drawBox(button, fillColor, {1, 1, 1})
    drawText(button.label, button.x + 10, button.y + 10, {1, 1, 1})
end

-- ============================================================================
-- PLAYER RENDERING
-- ============================================================================

function CombatRenderer.drawPlayer(world)
    local box = CombatUI.getPlayerBox()
    local player = world.player

    -- Player box
    drawBox(box, {0.2, 0.3, 0.6}, {1, 1, 1})

    -- Player name
    drawText(player.id, box.x + 10, box.y + 10, {1, 1, 1}, 1.2)

    -- HP bar
    local hpBarY = box.y + 40
    local hpBarWidth = box.width - 20
    local hpPercent = player.hp / player.maxHp

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", box.x + 10, hpBarY, hpBarWidth, 20)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", box.x + 10, hpBarY, hpBarWidth * hpPercent, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", box.x + 10, hpBarY, hpBarWidth, 20)

    drawText(string.format("HP: %d/%d", player.hp, player.maxHp),
        box.x + 15, hpBarY + 2, {1, 1, 1}, 0.8)

    -- Energy
    drawText(string.format("Energy: %d/%d", player.energy, player.maxEnergy),
        box.x + 10, box.y + 70, {0.7, 0.9, 1})

    -- Block
    if player.block > 0 then
        drawText(string.format("Block: %d", player.block),
            box.x + 10, box.y + 90, {0.7, 0.7, 1})
    end

    -- Status effects
    local statusY = box.y + 110
    if player.status then
        if player.status.vulnerable and player.status.vulnerable > 0 then
            drawText(string.format("Vulnerable: %d", player.status.vulnerable),
                box.x + 10, statusY, {1, 0.5, 0.5}, 0.7)
            statusY = statusY + 15
        end
        if player.status.weak and player.status.weak > 0 then
            drawText(string.format("Weak: %d", player.status.weak),
                box.x + 10, statusY, {0.8, 0.6, 0.4}, 0.7)
            statusY = statusY + 15
        end
        if player.status.thorns and player.status.thorns > 0 then
            drawText(string.format("Thorns: %d", player.status.thorns),
                box.x + 10, statusY, {0.6, 0.8, 0.6}, 0.7)
        end
    end
end

-- ============================================================================
-- ENEMY RENDERING
-- ============================================================================

function CombatRenderer.drawEnemies(world, hoveredEnemyIndex, targetMode)
    if not world.enemies or #world.enemies == 0 then
        return
    end

    for i, enemy in ipairs(world.enemies) do
        if enemy.hp > 0 then
            local box = CombatUI.getEnemyBox(i, #world.enemies)
            local isHovered = (hoveredEnemyIndex == i)

            -- Highlight if in target mode and hovered
            local fillColor = {0.6, 0.2, 0.2}
            if targetMode and isHovered then
                fillColor = {0.8, 0.3, 0.3}
            end

            drawBox(box, fillColor, {1, 1, 1})

            -- Enemy name
            drawText(enemy.name, box.x + 5, box.y + 5, {1, 1, 1}, 0.9)

            -- HP bar
            local hpBarY = box.y + 25
            local hpBarWidth = box.width - 10
            local hpPercent = enemy.hp / enemy.maxHp

            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", box.x + 5, hpBarY, hpBarWidth, 15)
            love.graphics.setColor(0.8, 0.2, 0.2)
            love.graphics.rectangle("fill", box.x + 5, hpBarY, hpBarWidth * hpPercent, 15)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", box.x + 5, hpBarY, hpBarWidth, 15)

            drawText(string.format("%d/%d", enemy.hp, enemy.maxHp),
                box.x + 10, hpBarY + 1, {1, 1, 1}, 0.7)

            -- Status effects
            local statusY = box.y + 50
            if enemy.status then
                if enemy.status.vulnerable and enemy.status.vulnerable > 0 then
                    drawText(string.format("Vuln: %d", enemy.status.vulnerable),
                        box.x + 5, statusY, {1, 0.5, 0.5}, 0.6)
                    statusY = statusY + 12
                end
                if enemy.status.weak and enemy.status.weak > 0 then
                    drawText(string.format("Weak: %d", enemy.status.weak),
                        box.x + 5, statusY, {0.8, 0.6, 0.4}, 0.6)
                end
            end
        end
    end
end

-- ============================================================================
-- HAND RENDERING
-- ============================================================================

function CombatRenderer.drawHand(world, hoveredCardIndex)
    local hand = CombatEngine.getCardsByState(world.player, "HAND")

    if #hand == 0 then
        drawText("(Hand is empty)", 400, 650, {0.5, 0.5, 0.5})
        return
    end

    for i, card in ipairs(hand) do
        local box = CombatUI.getCardBox(i, #hand)
        local isHovered = (hoveredCardIndex == i)

        -- Card background (different color if hovered)
        local fillColor = isHovered and {0.3, 0.7, 0.4} or {0.2, 0.6, 0.3}
        drawBox(box, fillColor, {1, 1, 1})

        -- Card name
        drawText(card.name, box.x + 5, box.y + 10, {1, 1, 1}, 0.7)

        -- Card cost
        local cost = GetCost.execute(world, world.player, card)
        drawText("Cost: " .. cost, box.x + 5, box.y + 30, {0.7, 0.9, 1}, 0.8)

        -- Card type
        local cardType = card.cardType or "?"
        drawText(cardType, box.x + 5, box.y + 50, {0.8, 0.8, 0.8}, 0.6)
    end
end

-- ============================================================================
-- UI ELEMENTS
-- ============================================================================

function CombatRenderer.drawEndTurnButton(hovered)
    local button = CombatUI.getEndTurnButton()
    drawButton(button, hovered)
end

-- ============================================================================
-- POPUP CARD SELECTION
-- ============================================================================

function CombatRenderer.drawCardSelectionPopup(selectableCards, selectedIndices, bounds, hoveredCardIndex, hoveredButton)
    local popup = CombatUI.getPopupBox()

    -- Darken background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, CombatUI.SCREEN_WIDTH, CombatUI.SCREEN_HEIGHT)

    -- Popup box
    drawBox(popup, {0.1, 0.1, 0.15}, {1, 1, 1})

    -- Title
    drawText("Select Cards", popup.x + 20, popup.y + 20, {1, 1, 1}, 1.2)

    -- Selection info
    local minSelect = bounds.min or 1
    local maxSelect = bounds.max or 1
    local selectionText = string.format("Selected: %d / %d (need %d-%d)",
        #selectedIndices, maxSelect, minSelect, maxSelect)
    drawText(selectionText, popup.x + 20, popup.y + 40, {0.9, 0.9, 0.9}, 0.8)

    -- Draw cards in grid
    for i, card in ipairs(selectableCards) do
        local box = CombatUI.getPopupCardBox(i)
        local isSelected = false
        for _, idx in ipairs(selectedIndices) do
            if idx == i then
                isSelected = true
                break
            end
        end

        local isHovered = (hoveredCardIndex == i)

        -- Card background
        local fillColor
        if isSelected then
            fillColor = {0.3, 0.8, 0.3}
        elseif isHovered then
            fillColor = {0.4, 0.5, 0.6}
        else
            fillColor = {0.2, 0.3, 0.4}
        end

        drawBox(box, fillColor, {1, 1, 1})

        -- Card name
        drawText(card.name, box.x + 5, box.y + 5, {1, 1, 1}, 0.6)

        -- Selected marker
        if isSelected then
            drawText("*", box.x + box.width - 15, box.y + 5, {1, 1, 0}, 1.2)
        end
    end

    -- Submit button
    local submitBtn = CombatUI.getPopupSubmitButton()
    local canSubmit = #selectedIndices >= minSelect
    local submitColor = canSubmit and (hoveredButton == "submit" and {0.3, 0.7, 0.3} or {0.2, 0.6, 0.2}) or {0.3, 0.3, 0.3}
    drawBox(submitBtn, submitColor, {1, 1, 1})
    drawText(submitBtn.label, submitBtn.x + 10, submitBtn.y + 10, {1, 1, 1})

    -- Cancel button
    local cancelBtn = CombatUI.getPopupCancelButton()
    drawButton(cancelBtn, hoveredButton == "cancel")
end

-- ============================================================================
-- MAIN DRAW FUNCTION
-- ============================================================================

function CombatRenderer.draw(world, state)
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)

    -- Draw main game elements
    CombatRenderer.drawPlayer(world)
    CombatRenderer.drawEnemies(world, state.hoveredEnemyIndex, state.mode == "target")
    CombatRenderer.drawHand(world, state.hoveredCardIndex)
    CombatRenderer.drawEndTurnButton(state.hoveredEndTurnButton)

    -- Draw popup if in card selection mode
    if state.mode == "cardselect" and state.cardSelectionState then
        local cs = state.cardSelectionState
        CombatRenderer.drawCardSelectionPopup(
            cs.selectableCards,
            cs.selectedIndices,
            cs.bounds,
            cs.hoveredCardIndex,
            cs.hoveredButton
        )
    end

    -- Game over overlay
    if not state.gameActive and state.lastResult then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 200, 300, 600, 150)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 200, 300, 600, 150)

        if state.lastResult == "victory" then
            drawText("VICTORY!", 400, 330, {0.3, 1, 0.3}, 2)
        elseif state.lastResult == "defeat" then
            drawText("DEFEAT!", 400, 330, {1, 0.3, 0.3}, 2)
        else
            drawText("Combat Ended", 380, 330, {0.7, 0.7, 0.7}, 1.5)
        end

        drawText("Press ESC to return to menu", 340, 400, {1, 1, 1})
    end

    -- Mode indicator (debug)
    drawText("Mode: " .. (state.mode or "?"), 10, 10, {0.5, 0.5, 0.5}, 0.7)
end

return CombatRenderer
