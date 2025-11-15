-- COMBAT UI HELPER
-- Handles layout calculations and hitbox detection

local CombatUI = {}

-- Layout constants
local SCREEN_WIDTH = 1024
local SCREEN_HEIGHT = 768

local PLAYER_X = 100
local PLAYER_Y = 250
local PLAYER_WIDTH = 150
local PLAYER_HEIGHT = 200

local ENEMY_START_X = 650
local ENEMY_Y = 200
local ENEMY_WIDTH = 120
local ENEMY_HEIGHT = 150
local ENEMY_SPACING = 20

local HAND_Y = 580
local HAND_START_X = 150
local CARD_WIDTH = 120
local CARD_HEIGHT = 160
local CARD_SPACING = 10

local BUTTON_WIDTH = 100
local BUTTON_HEIGHT = 40
local END_TURN_X = 20
local END_TURN_Y = 680

local POPUP_WIDTH = 700
local POPUP_HEIGHT = 500
local POPUP_X = (SCREEN_WIDTH - POPUP_WIDTH) / 2
local POPUP_Y = (SCREEN_HEIGHT - POPUP_HEIGHT) / 2
local POPUP_CARD_WIDTH = 100
local POPUP_CARD_HEIGHT = 130
local POPUP_CARD_SPACING = 10
local POPUP_CARDS_PER_ROW = 6

-- Export constants
CombatUI.SCREEN_WIDTH = SCREEN_WIDTH
CombatUI.SCREEN_HEIGHT = SCREEN_HEIGHT

-- ============================================================================
-- PLAYER LAYOUT
-- ============================================================================

function CombatUI.getPlayerBox()
    return {
        x = PLAYER_X,
        y = PLAYER_Y,
        width = PLAYER_WIDTH,
        height = PLAYER_HEIGHT
    }
end

-- ============================================================================
-- ENEMY LAYOUT
-- ============================================================================

function CombatUI.getEnemyBox(index, totalEnemies)
    local spacing = (totalEnemies > 1) and ENEMY_SPACING or 0
    local x = ENEMY_START_X + (index - 1) * (ENEMY_WIDTH + spacing)

    return {
        x = x,
        y = ENEMY_Y,
        width = ENEMY_WIDTH,
        height = ENEMY_HEIGHT
    }
end

function CombatUI.isPointInBox(px, py, box)
    return px >= box.x and px <= box.x + box.width and
           py >= box.y and py <= box.y + box.height
end

function CombatUI.getEnemyAtPoint(enemies, x, y)
    for i, enemy in ipairs(enemies) do
        if enemy.hp > 0 then
            local box = CombatUI.getEnemyBox(i, #enemies)
            if CombatUI.isPointInBox(x, y, box) then
                return enemy, i
            end
        end
    end
    return nil
end

-- ============================================================================
-- HAND LAYOUT
-- ============================================================================

function CombatUI.getCardBox(index, handSize)
    local totalWidth = handSize * CARD_WIDTH + (handSize - 1) * CARD_SPACING
    local startX = (SCREEN_WIDTH - totalWidth) / 2
    local x = startX + (index - 1) * (CARD_WIDTH + CARD_SPACING)

    return {
        x = x,
        y = HAND_Y,
        width = CARD_WIDTH,
        height = CARD_HEIGHT
    }
end

function CombatUI.getCardAtPoint(handSize, x, y)
    for i = 1, handSize do
        local box = CombatUI.getCardBox(i, handSize)
        if CombatUI.isPointInBox(x, y, box) then
            return i
        end
    end
    return nil
end

-- ============================================================================
-- BUTTONS
-- ============================================================================

function CombatUI.getEndTurnButton()
    return {
        x = END_TURN_X,
        y = END_TURN_Y,
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT,
        label = "End Turn"
    }
end

-- ============================================================================
-- POPUP CARD SELECTION
-- ============================================================================

function CombatUI.getPopupBox()
    return {
        x = POPUP_X,
        y = POPUP_Y,
        width = POPUP_WIDTH,
        height = POPUP_HEIGHT
    }
end

function CombatUI.getPopupCardBox(index)
    local row = math.floor((index - 1) / POPUP_CARDS_PER_ROW)
    local col = (index - 1) % POPUP_CARDS_PER_ROW

    local x = POPUP_X + 20 + col * (POPUP_CARD_WIDTH + POPUP_CARD_SPACING)
    local y = POPUP_Y + 60 + row * (POPUP_CARD_HEIGHT + POPUP_CARD_SPACING)

    return {
        x = x,
        y = y,
        width = POPUP_CARD_WIDTH,
        height = POPUP_CARD_HEIGHT
    }
end

function CombatUI.getPopupCardAtPoint(cardCount, x, y)
    for i = 1, cardCount do
        local box = CombatUI.getPopupCardBox(i)
        if CombatUI.isPointInBox(x, y, box) then
            return i
        end
    end
    return nil
end

function CombatUI.getPopupSubmitButton()
    return {
        x = POPUP_X + POPUP_WIDTH - 120,
        y = POPUP_Y + POPUP_HEIGHT - 60,
        width = 100,
        height = 40,
        label = "Submit"
    }
end

function CombatUI.getPopupCancelButton()
    return {
        x = POPUP_X + 20,
        y = POPUP_Y + POPUP_HEIGHT - 60,
        width = 100,
        height = 40,
        label = "Cancel"
    }
end

return CombatUI
