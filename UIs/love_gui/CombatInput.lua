-- COMBAT INPUT HANDLER
-- Handles all mouse input and click detection

local CombatInput = {}
local CombatUI = require("UIs.love_gui.CombatUI")
local CombatEngine = require("CombatEngine")

-- ============================================================================
-- MOUSE POSITION TRACKING
-- ============================================================================

function CombatInput.updateHover(state, world)
    local mx, my = love.mouse.getPosition()

    -- Reset hover states
    state.hoveredCardIndex = nil
    state.hoveredEnemyIndex = nil
    state.hoveredEndTurnButton = false

    if state.mode == "cardselect" and state.cardSelectionState then
        -- Popup hover detection
        local cs = state.cardSelectionState
        cs.hoveredCardIndex = CombatUI.getPopupCardAtPoint(#cs.selectableCards, mx, my)

        local submitBtn = CombatUI.getPopupSubmitButton()
        local cancelBtn = CombatUI.getPopupCancelButton()

        if CombatUI.isPointInBox(mx, my, submitBtn) then
            cs.hoveredButton = "submit"
        elseif CombatUI.isPointInBox(mx, my, cancelBtn) then
            cs.hoveredButton = "cancel"
        else
            cs.hoveredButton = nil
        end
    else
        -- Normal game hover detection
        local hand = CombatEngine.getCardsByState(world.player, "HAND")
        state.hoveredCardIndex = CombatUI.getCardAtPoint(#hand, mx, my)

        if world.enemies then
            local _, enemyIndex = CombatUI.getEnemyAtPoint(world.enemies, mx, my)
            state.hoveredEnemyIndex = enemyIndex
        end

        local endTurnBtn = CombatUI.getEndTurnButton()
        state.hoveredEndTurnButton = CombatUI.isPointInBox(mx, my, endTurnBtn)
    end
end

-- ============================================================================
-- CLICK HANDLING - ACTION MODE
-- ============================================================================

function CombatInput.handleActionClick(state, world, x, y)
    -- Check End Turn button
    local endTurnBtn = CombatUI.getEndTurnButton()
    if CombatUI.isPointInBox(x, y, endTurnBtn) then
        state.pendingAction = {type = "end"}
        return
    end

    -- Check if clicked on a card in hand
    local hand = CombatEngine.getCardsByState(world.player, "HAND")
    local cardIndex = CombatUI.getCardAtPoint(#hand, x, y)
    if cardIndex then
        state.pendingAction = {type = "play", cardIndex = cardIndex}
        return
    end
end

-- ============================================================================
-- CLICK HANDLING - TARGET MODE
-- ============================================================================

function CombatInput.handleTargetClick(state, world, x, y)
    if not world.enemies then
        return
    end

    local enemy = CombatUI.getEnemyAtPoint(world.enemies, x, y)
    if enemy then
        state.pendingContext = enemy
        state.pendingContextStatus = "ok"
        state.mode = "action"
    end
end

-- ============================================================================
-- CLICK HANDLING - CARD SELECT MODE
-- ============================================================================

function CombatInput.handleCardSelectClick(state, world, x, y)
    if not state.cardSelectionState then
        return
    end

    local cs = state.cardSelectionState

    -- Check Submit button
    local submitBtn = CombatUI.getPopupSubmitButton()
    if CombatUI.isPointInBox(x, y, submitBtn) then
        local minSelect = cs.bounds.min or 1
        if #cs.selectedIndices >= minSelect then
            -- Build selected cards array
            local selectedCards = {}
            for _, idx in ipairs(cs.selectedIndices) do
                table.insert(selectedCards, cs.selectableCards[idx])
            end

            state.pendingContext = selectedCards
            state.pendingContextStatus = "ok"
            state.mode = "action"
            state.cardSelectionState = nil
        end
        return
    end

    -- Check Cancel button
    local cancelBtn = CombatUI.getPopupCancelButton()
    if CombatUI.isPointInBox(x, y, cancelBtn) then
        state.pendingContext = nil
        state.pendingContextStatus = "cancel"
        state.mode = "action"
        state.cardSelectionState = nil
        return
    end

    -- Check if clicked on a card
    local cardIndex = CombatUI.getPopupCardAtPoint(#cs.selectableCards, x, y)
    if cardIndex then
        -- Toggle selection
        local found = false
        for i, idx in ipairs(cs.selectedIndices) do
            if idx == cardIndex then
                table.remove(cs.selectedIndices, i)
                found = true
                break
            end
        end

        if not found then
            local maxSelect = cs.bounds.max or 1
            if #cs.selectedIndices < maxSelect then
                table.insert(cs.selectedIndices, cardIndex)
            end
        end
    end
end

-- ============================================================================
-- MAIN CLICK DISPATCHER
-- ============================================================================

function CombatInput.mousepressed(state, world, x, y, button)
    if button ~= 1 then -- Only left click
        return
    end

    if not state.gameActive then
        return
    end

    if state.mode == "action" then
        CombatInput.handleActionClick(state, world, x, y)
    elseif state.mode == "target" then
        CombatInput.handleTargetClick(state, world, x, y)
    elseif state.mode == "cardselect" then
        CombatInput.handleCardSelectClick(state, world, x, y)
    end
end

return CombatInput
