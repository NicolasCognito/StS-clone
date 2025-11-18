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

    -- All status effects (dynamic display)
    local statusY = box.y + 110
    if player.status then
        local StatusEffects = require("Data.statuseffects")
        local statusCount = 0
        for statusKey, statusValue in pairs(player.status) do
            if type(statusValue) == "number" and statusValue > 0 then
                local statusDef = StatusEffects[statusKey]
                if statusDef then
                    local displayName = statusDef.shortName or statusDef.name or statusKey
                    local color = statusDef.debuff and {1, 0.5, 0.5} or {0.5, 1, 0.5}
                    drawText(string.format("%s: %d", displayName, statusValue),
                        box.x + 10, statusY, color, 0.65)
                    statusY = statusY + 13
                    statusCount = statusCount + 1
                    -- Limit display to avoid overflow
                    if statusCount >= 8 then
                        drawText("...", box.x + 10, statusY, {0.7, 0.7, 0.7}, 0.6)
                        break
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- ORB RENDERING
-- ============================================================================

function CombatRenderer.drawOrbs(world)
    local player = world.player
    if not player then return end

    local maxOrbs = player.maxOrbs or 0
    if maxOrbs == 0 then return end  -- No orb slots (not Defect)

    local orbs = player.orbs or {}

    -- Orb display positioning (right side of player box)
    local orbStartX = 270
    local orbY = 260
    local orbSize = 30
    local orbSpacing = 10

    -- Draw label
    drawText("Orbs:", orbStartX, orbY - 20, {0.8, 0.8, 1}, 0.8)

    -- Draw all orb slots (filled and empty)
    for i = 1, maxOrbs do
        local x = orbStartX + (i - 1) * (orbSize + orbSpacing)
        local orb = orbs[i]

        if orb then
            -- Filled orb slot - color based on orb type
            local orbColor = {0.5, 0.5, 0.5}  -- Default gray
            local orbText = "?"

            if orb.id == "Lightning" then
                orbColor = {0.3, 0.6, 1}  -- Blue
                orbText = "⚡"
            elseif orb.id == "Frost" then
                orbColor = {0.6, 0.9, 1}  -- Light blue
                orbText = "❄"
            elseif orb.id == "Dark" then
                orbColor = {0.4, 0.2, 0.5}  -- Purple
                orbText = "●"
            elseif orb.id == "Plasma" then
                orbColor = {1, 0.6, 0.2}  -- Orange
                orbText = "⚛"
            end

            -- Draw filled orb
            love.graphics.setColor(orbColor)
            love.graphics.circle("fill", x + orbSize/2, orbY + orbSize/2, orbSize/2)
            love.graphics.setColor(1, 1, 1)
            love.graphics.circle("line", x + orbSize/2, orbY + orbSize/2, orbSize/2)

            -- Draw orb symbol/text
            drawText(orbText, x + 8, orbY + 8, {1, 1, 1}, 1)

            -- For Dark orbs, show accumulated damage
            if orb.id == "Dark" and orb.damage then
                drawText(tostring(orb.damage), x + orbSize/2 - 5, orbY + orbSize + 3, {1, 1, 0}, 0.7)
            end
        else
            -- Empty orb slot
            love.graphics.setColor(0.2, 0.2, 0.3)
            love.graphics.circle("fill", x + orbSize/2, orbY + orbSize/2, orbSize/2)
            love.graphics.setColor(0.5, 0.5, 0.6)
            love.graphics.circle("line", x + orbSize/2, orbY + orbSize/2, orbSize/2)
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

            -- Enhanced highlighting when in target mode
            local fillColor = {0.6, 0.2, 0.2}
            local lineColor = {1, 1, 1}
            local lineWidth = 1

            if targetMode then
                if isHovered then
                    -- Bright highlight for hovered enemy in target mode
                    fillColor = {0.9, 0.4, 0.4}
                    lineColor = {1, 1, 0}  -- Yellow border
                    lineWidth = 3
                else
                    -- Slightly brighten all enemies in target mode
                    fillColor = {0.7, 0.25, 0.25}
                end
            end

            -- Draw box with enhanced highlighting
            love.graphics.setLineWidth(lineWidth)
            drawBox(box, fillColor, lineColor)
            love.graphics.setLineWidth(1)  -- Reset line width

            -- Enemy name
            drawText(enemy.name, box.x + 5, box.y + 5, {1, 1, 1}, 0.9)

            -- Enemy intention
            if enemy.currentIntent then
                local intentName = enemy.currentIntent.name or "?"
                local intentColor = {1, 1, 0.5}  -- Yellow for intent
                drawText("» " .. intentName, box.x + 5, box.y + 20, intentColor, 0.6)
            end

            -- HP bar
            local hpBarY = box.y + 35
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

            -- Block display
            if enemy.block and enemy.block > 0 then
                drawText(string.format("Block: %d", enemy.block),
                    box.x + 5, hpBarY + 15, {0.7, 0.7, 1}, 0.6)
            end

            -- All status effects (dynamic display)
            local statusY = box.y + 60
            if enemy.status then
                local StatusEffects = require("Data.statuseffects")
                for statusKey, statusValue in pairs(enemy.status) do
                    if type(statusValue) == "number" and statusValue > 0 then
                        local statusDef = StatusEffects[statusKey]
                        if statusDef then
                            local displayName = statusDef.shortName or statusDef.name or statusKey
                            local color = statusDef.debuff and {1, 0.5, 0.5} or {0.5, 1, 0.5}
                            drawText(string.format("%s: %d", displayName, statusValue),
                                box.x + 5, statusY, color, 0.55)
                            statusY = statusY + 11
                        end
                    end
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

    local IsPlayable = require("Pipelines.IsPlayable")

    for i, card in ipairs(hand) do
        local box = CombatUI.getCardBox(i, #hand)
        local isHovered = (hoveredCardIndex == i)

        -- Check if card is playable
        local playable, errorMsg = IsPlayable.execute(world, world.player, card)

        -- Card background with playability indication
        local fillColor, lineColor, lineWidth

        if playable then
            -- Playable cards: green, brighter when hovered
            fillColor = isHovered and {0.3, 0.8, 0.4} or {0.2, 0.6, 0.3}
            lineColor = isHovered and {0.5, 1, 0.5} or {1, 1, 1}
            lineWidth = isHovered and 2 or 1
        else
            -- Unplayable cards: dimmed/grayed out
            fillColor = {0.3, 0.3, 0.3}
            lineColor = {0.6, 0.6, 0.6}
            lineWidth = 1
        end

        love.graphics.setLineWidth(lineWidth)
        drawBox(box, fillColor, lineColor)
        love.graphics.setLineWidth(1)

        -- Card name (dim text if unplayable)
        local textColor = playable and {1, 1, 1} or {0.6, 0.6, 0.6}
        drawText(card.name, box.x + 5, box.y + 10, textColor, 0.7)

        -- Card cost (highlight if not enough energy)
        local cost = GetCost.execute(world, world.player, card)
        local costColor = (world.player.energy >= cost) and {0.7, 0.9, 1} or {1, 0.4, 0.4}
        if not playable then costColor = {0.6, 0.6, 0.6} end
        drawText("Cost: " .. cost, box.x + 5, box.y + 30, costColor, 0.8)

        -- Card type
        local cardType = card.cardType or "?"
        drawText(cardType, box.x + 5, box.y + 50, textColor, 0.6)

        -- Show error message if hovered and unplayable
        if isHovered and not playable and errorMsg then
            -- Draw tooltip below card
            local tooltipY = box.y + box.height + 5
            love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
            love.graphics.rectangle("fill", box.x - 5, tooltipY, box.width + 10, 25)
            love.graphics.setColor(1, 0.5, 0.5)
            love.graphics.rectangle("line", box.x - 5, tooltipY, box.width + 10, 25)
            drawText(errorMsg, box.x, tooltipY + 5, {1, 0.7, 0.7}, 0.5)
        end
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
    CombatRenderer.drawOrbs(world)
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
