-- DECKBUILDER LOVE2D UI
-- Three-mode deckbuilder: Relics -> Cards -> Upgrades -> Save/Test

local DeckbuilderLove = {}

local Cards = require("Data.cards")
local Relics = require("Data.relics")
local Enemies = require("Data.enemies")
local DeckSerializer = require("DeckSerializer")
local Utils = require("utils")

-- ============================================================================
-- UI STATE
-- ============================================================================

local state = {
    mode = "character",  -- "character", "relics", "cards", "upgrades", "save", "testcombat"

    -- Character selection
    selectedCharacter = "IRONCLAD",
    allowAllCards = false,  -- Toggle for allowing all cards regardless of character

    -- Relic selection
    selectedRelics = {},
    hoveredRelicIndex = nil,
    relicScroll = 0,

    -- Card selection
    selectedCards = {},  -- Array of {cardDef, upgraded=false}
    hoveredCardIndex = nil,
    cardScroll = 0,
    cardFilter = "ALL",  -- "ALL", "ATTACK", "SKILL", "POWER"

    -- Upgrade mode
    hoveredUpgradeCardIndex = nil,
    upgradeScroll = 0,

    -- Save mode
    deckName = "",
    hoveredSaveButton = nil,

    -- Test Combat mode
    savedDecks = {},
    selectedDeckIndex = nil,
    hoveredDeckIndex = nil,
    selectedEnemyIndex = 1,
    hoveredEnemyIndex = nil,
    enemyList = {},
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function getAllRelics()
    local relicList = {}
    for key, relic in pairs(Relics) do
        table.insert(relicList, relic)
    end
    table.sort(relicList, function(a, b)
        return a.name < b.name
    end)
    return relicList
end

local function getAllCards()
    local cardList = {}
    for key, card in pairs(Cards) do
        if state.allowAllCards then
            -- Allow all cards
            table.insert(cardList, card)
        else
            -- Only character-specific + colorless + curses
            if card.character == state.selectedCharacter or
               card.character == "COLORLESS" or
               card.type == "CURSE" or
               card.type == "STATUS" then
                table.insert(cardList, card)
            end
        end
    end
    table.sort(cardList, function(a, b)
        if a.type ~= b.type then
            local typeOrder = {ATTACK=1, SKILL=2, POWER=3, CURSE=4, STATUS=5}
            return (typeOrder[a.type] or 99) < (typeOrder[b.type] or 99)
        end
        return a.name < b.name
    end)
    return cardList
end

local function getFilteredCards()
    local cards = getAllCards()
    if state.cardFilter == "ALL" then
        return cards
    end

    local filtered = {}
    for _, card in ipairs(cards) do
        if card.type == state.cardFilter then
            table.insert(filtered, card)
        end
    end
    return filtered
end

local function getAllEnemies()
    local enemyList = {}
    for key, enemy in pairs(Enemies) do
        table.insert(enemyList, {key = key, data = enemy})
    end
    table.sort(enemyList, function(a, b)
        return a.data.name < b.data.name
    end)
    return enemyList
end

local function hasRelic(relicId)
    for _, relic in ipairs(state.selectedRelics) do
        if relic.id == relicId then
            return true
        end
    end
    return false
end

local function addRelic(relic)
    if not hasRelic(relic.id) then
        table.insert(state.selectedRelics, relic)
    end
end

local function removeRelic(relicId)
    for i, relic in ipairs(state.selectedRelics) do
        if relic.id == relicId then
            table.remove(state.selectedRelics, i)
            return
        end
    end
end

local function addCard(cardDef)
    table.insert(state.selectedCards, {cardDef = cardDef, upgraded = false})
end

local function removeCard(index)
    table.remove(state.selectedCards, index)
end

local function toggleUpgrade(index)
    if state.selectedCards[index] then
        state.selectedCards[index].upgraded = not state.selectedCards[index].upgraded
    end
end

local function loadSavedDecks()
    state.savedDecks = DeckSerializer.listDecks()
end

-- ============================================================================
-- DRAW FUNCTIONS
-- ============================================================================

local function drawButton(text, x, y, w, h, hovered)
    if hovered then
        love.graphics.setColor(0.4, 0.6, 0.8)
    else
        love.graphics.setColor(0.2, 0.3, 0.4)
    end
    love.graphics.rectangle("fill", x, y, w, h)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, w, h)

    local textW = love.graphics.getFont():getWidth(text)
    love.graphics.print(text, x + (w - textW) / 2, y + 10)
end

local function drawCharacterSelection()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SELECT CHARACTER", 50, 50, 0, 2, 2)

    local characters = {
        {name = "Ironclad", id = "IRONCLAD"},
        {name = "Silent", id = "SILENT"},
        {name = "Defect", id = "DEFECT"}
    }

    for i, char in ipairs(characters) do
        local y = 150 + (i - 1) * 60
        local selected = state.selectedCharacter == char.id

        if selected then
            love.graphics.setColor(0.4, 0.8, 0.4)
        else
            love.graphics.setColor(0.3, 0.3, 0.3)
        end
        love.graphics.rectangle("fill", 50, y, 300, 50)

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 50, y, 300, 50)
        love.graphics.print(char.name, 60, y + 15)
    end

    -- Allow All Cards toggle
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Card Pool:", 50, 350)

    local toggleY = 380
    if state.allowAllCards then
        love.graphics.setColor(0.4, 0.8, 0.4)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
    end
    love.graphics.rectangle("fill", 50, toggleY, 300, 50)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 50, toggleY, 300, 50)
    local toggleText = state.allowAllCards and "ALL CARDS (Any Character)" or "CHARACTER CARDS ONLY"
    love.graphics.print(toggleText, 60, toggleY + 15)

    drawButton("NEXT: Select Relics", 50, 500, 300, 40, false)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Click a character and card pool, then press NEXT", 50, 650)
end

local function drawRelicSelection()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SELECT RELICS (Mode 1/3)", 50, 30, 0, 1.5, 1.5)

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Selected: " .. #state.selectedRelics .. " relics", 50, 70)

    -- Draw relic list
    local relics = getAllRelics()
    local startY = 100
    local itemHeight = 60
    local visibleCount = 8

    for i = 1, math.min(visibleCount, #relics - state.relicScroll) do
        local idx = i + state.relicScroll
        local relic = relics[idx]
        local y = startY + (i - 1) * itemHeight
        local isSelected = hasRelic(relic.id)
        local isHovered = state.hoveredRelicIndex == idx

        if isSelected then
            love.graphics.setColor(0.3, 0.6, 0.3)
        elseif isHovered then
            love.graphics.setColor(0.4, 0.4, 0.5)
        else
            love.graphics.setColor(0.2, 0.2, 0.25)
        end
        love.graphics.rectangle("fill", 50, y, 600, itemHeight - 5)

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 50, y, 600, itemHeight - 5)

        love.graphics.print(relic.name, 60, y + 5)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf(relic.description or "No description", 60, y + 25, 500)

        if isSelected then
            love.graphics.setColor(0.3, 0.9, 0.3)
            love.graphics.print("✓ SELECTED", 580, y + 20)
        end
    end

    -- Scroll indicator
    if #relics > visibleCount then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(string.format("Scroll: %d-%d of %d (use mouse wheel)",
            state.relicScroll + 1,
            math.min(state.relicScroll + visibleCount, #relics),
            #relics), 50, 600)
    end

    -- Navigation buttons
    drawButton("BACK", 50, 650, 150, 40, false)
    drawButton("NEXT: Select Cards", 500, 650, 200, 40, false)
end

local function drawCardSelection()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SELECT CARDS (Mode 2/3)", 50, 30, 0, 1.5, 1.5)

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Deck: " .. #state.selectedCards .. " cards", 50, 70)

    -- Filter buttons
    local filters = {"ALL", "ATTACK", "SKILL", "POWER"}
    for i, filter in ipairs(filters) do
        local x = 50 + (i - 1) * 100
        local selected = state.cardFilter == filter

        if selected then
            love.graphics.setColor(0.4, 0.6, 0.8)
        else
            love.graphics.setColor(0.2, 0.3, 0.4)
        end
        love.graphics.rectangle("fill", x, 90, 90, 30)

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", x, 90, 90, 30)
        love.graphics.print(filter, x + 10, 95)
    end

    -- Draw card list
    local cards = getFilteredCards()
    local startY = 130
    local itemHeight = 50
    local visibleCount = 9

    for i = 1, math.min(visibleCount, #cards - state.cardScroll) do
        local idx = i + state.cardScroll
        local card = cards[idx]
        local y = startY + (i - 1) * itemHeight
        local isHovered = state.hoveredCardIndex == idx

        if isHovered then
            love.graphics.setColor(0.4, 0.4, 0.5)
        else
            love.graphics.setColor(0.2, 0.2, 0.25)
        end
        love.graphics.rectangle("fill", 50, y, 600, itemHeight - 5)

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 50, y, 600, itemHeight - 5)

        -- Card name with cost
        local costColor = {0.5, 0.8, 1}
        love.graphics.setColor(costColor)
        love.graphics.print("[" .. card.cost .. "]", 60, y + 5)

        love.graphics.setColor(1, 1, 1)
        love.graphics.print(card.name, 100, y + 5)

        -- Type
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print(card.type, 300, y + 5)

        -- Description
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf(card.description or "", 60, y + 25, 500)
    end

    -- Current deck display
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Current Deck:", 700, 130)

    local deckY = 160
    for i, cardInfo in ipairs(state.selectedCards) do
        if deckY > 600 then
            love.graphics.print("... +" .. (#state.selectedCards - i + 1) .. " more", 700, deckY)
            break
        end

        love.graphics.setColor(0.8, 0.8, 0.8)
        local displayName = cardInfo.cardDef.name
        if cardInfo.upgraded then
            displayName = displayName .. "+"
        end
        love.graphics.print(displayName, 700, deckY)
        deckY = deckY + 20
    end

    -- Scroll indicator
    if #cards > visibleCount then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(string.format("Scroll: %d-%d of %d",
            state.cardScroll + 1,
            math.min(state.cardScroll + visibleCount, #cards),
            #cards), 50, 600)
    end

    -- Navigation buttons
    drawButton("BACK", 50, 650, 150, 40, false)
    drawButton("REMOVE LAST", 220, 650, 150, 40, false)
    drawButton("NEXT: Upgrades", 500, 650, 200, 40, false)
end

local function drawUpgradeSelection()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("UPGRADE CARDS (Mode 3/3)", 50, 30, 0, 1.5, 1.5)

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Click cards to toggle upgrades", 50, 70)

    -- Draw card list
    local startY = 110
    local itemHeight = 60
    local visibleCount = 8

    for i = 1, math.min(visibleCount, #state.selectedCards - state.upgradeScroll) do
        local idx = i + state.upgradeScroll
        local cardInfo = state.selectedCards[idx]
        local y = startY + (i - 1) * itemHeight
        local isHovered = state.hoveredUpgradeCardIndex == idx

        if cardInfo.upgraded then
            love.graphics.setColor(0.3, 0.6, 0.3)
        elseif isHovered then
            love.graphics.setColor(0.4, 0.4, 0.5)
        else
            love.graphics.setColor(0.2, 0.2, 0.25)
        end
        love.graphics.rectangle("fill", 50, y, 600, itemHeight - 5)

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 50, y, 600, itemHeight - 5)

        local displayName = cardInfo.cardDef.name
        if cardInfo.upgraded then
            displayName = displayName .. "+"
            love.graphics.setColor(0.3, 0.9, 0.3)
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.print(displayName, 60, y + 10)

        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(cardInfo.cardDef.type, 300, y + 10)

        if cardInfo.upgraded then
            love.graphics.setColor(0.3, 0.9, 0.3)
            love.graphics.print("✓ UPGRADED", 500, y + 20)
        end
    end

    -- Scroll indicator
    if #state.selectedCards > visibleCount then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(string.format("Scroll: %d-%d of %d",
            state.upgradeScroll + 1,
            math.min(state.upgradeScroll + visibleCount, #state.selectedCards),
            #state.selectedCards), 50, 600)
    end

    -- Navigation buttons
    drawButton("BACK", 50, 650, 150, 40, false)
    drawButton("SAVE DECK", 500, 650, 200, 40, false)
end

local function drawSaveMode()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SAVE DECK", 50, 50, 0, 2, 2)

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Deck Name:", 50, 150)

    -- Text input box
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 50, 180, 400, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 50, 180, 400, 40)
    love.graphics.print(state.deckName .. "_", 60, 190)

    -- Deck summary
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Character: " .. state.selectedCharacter, 50, 250)
    love.graphics.print("Relics: " .. #state.selectedRelics, 50, 280)
    love.graphics.print("Cards: " .. #state.selectedCards, 50, 310)

    local upgraded = 0
    for _, cardInfo in ipairs(state.selectedCards) do
        if cardInfo.upgraded then
            upgraded = upgraded + 1
        end
    end
    love.graphics.print("Upgraded Cards: " .. upgraded, 50, 340)

    -- Buttons
    drawButton("BACK", 50, 500, 150, 40, false)
    drawButton("SAVE & EXIT", 250, 500, 200, 40, state.hoveredSaveButton == 1)
    drawButton("SAVE & TEST", 500, 500, 200, 40, state.hoveredSaveButton == 2)

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Type a name and click SAVE", 50, 600)
end

local function drawTestCombat()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("TEST COMBAT", 50, 50, 0, 2, 2)

    -- Deck selection
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Select Deck:", 50, 130)

    local startY = 160
    for i, deckName in ipairs(state.savedDecks) do
        local y = startY + (i - 1) * 40
        local selected = state.selectedDeckIndex == i
        local hovered = state.hoveredDeckIndex == i

        if selected then
            love.graphics.setColor(0.3, 0.6, 0.3)
        elseif hovered then
            love.graphics.setColor(0.4, 0.4, 0.5)
        else
            love.graphics.setColor(0.2, 0.2, 0.25)
        end
        love.graphics.rectangle("fill", 50, y, 300, 35)

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 50, y, 300, 35)
        love.graphics.print(deckName, 60, y + 8)
    end

    if #state.savedDecks == 0 then
        love.graphics.setColor(0.7, 0.3, 0.3)
        love.graphics.print("No saved decks found!", 50, 160)
    end

    -- Enemy selection
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Select Enemy:", 400, 130)

    startY = 160
    for i, enemy in ipairs(state.enemyList) do
        local y = startY + (i - 1) * 40
        local selected = state.selectedEnemyIndex == i
        local hovered = state.hoveredEnemyIndex == i

        if selected then
            love.graphics.setColor(0.6, 0.3, 0.3)
        elseif hovered then
            love.graphics.setColor(0.4, 0.4, 0.5)
        else
            love.graphics.setColor(0.2, 0.2, 0.25)
        end
        love.graphics.rectangle("fill", 400, y, 300, 35)

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 400, y, 300, 35)
        love.graphics.print(enemy.data.name, 410, y + 8)
    end

    -- Buttons
    drawButton("BACK TO MENU", 50, 650, 200, 40, false)
    drawButton("START COMBAT", 500, 650, 200, 40, false)

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Select a deck and enemy, then click START", 50, 600)
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

local function handleCharacterClick(x, y)
    local characters = {"IRONCLAD", "SILENT", "DEFECT"}

    for i, char in ipairs(characters) do
        local btnY = 150 + (i - 1) * 60
        if x >= 50 and x <= 350 and y >= btnY and y <= btnY + 50 then
            state.selectedCharacter = char
            return
        end
    end

    -- Card pool toggle
    if x >= 50 and x <= 350 and y >= 380 and y <= 430 then
        state.allowAllCards = not state.allowAllCards
        return
    end

    -- Next button
    if x >= 50 and x <= 350 and y >= 500 and y <= 540 then
        state.mode = "relics"
        state.selectedRelics = {}
    end
end

local function handleRelicClick(x, y)
    -- Back button
    if x >= 50 and x <= 200 and y >= 650 and y <= 690 then
        state.mode = "character"
        return
    end

    -- Next button
    if x >= 500 and x <= 700 and y >= 650 and y <= 690 then
        state.mode = "cards"
        state.selectedCards = {}
        return
    end

    -- Relic list
    local relics = getAllRelics()
    local startY = 100
    local itemHeight = 60
    local visibleCount = 8

    for i = 1, math.min(visibleCount, #relics - state.relicScroll) do
        local idx = i + state.relicScroll
        local itemY = startY + (i - 1) * itemHeight

        if x >= 50 and x <= 650 and y >= itemY and y <= itemY + itemHeight - 5 then
            local relic = relics[idx]
            if hasRelic(relic.id) then
                removeRelic(relic.id)
            else
                addRelic(relic)
            end
            return
        end
    end
end

local function handleCardClick(x, y)
    -- Back button
    if x >= 50 and x <= 200 and y >= 650 and y <= 690 then
        state.mode = "relics"
        return
    end

    -- Remove last button
    if x >= 220 and x <= 370 and y >= 650 and y <= 690 then
        if #state.selectedCards > 0 then
            removeCard(#state.selectedCards)
        end
        return
    end

    -- Next button
    if x >= 500 and x <= 700 and y >= 650 and y <= 690 then
        state.mode = "upgrades"
        return
    end

    -- Filter buttons
    local filters = {"ALL", "ATTACK", "SKILL", "POWER"}
    for i, filter in ipairs(filters) do
        local btnX = 50 + (i - 1) * 100
        if x >= btnX and x <= btnX + 90 and y >= 90 and y <= 120 then
            state.cardFilter = filter
            state.cardScroll = 0
            return
        end
    end

    -- Card list
    local cards = getFilteredCards()
    local startY = 130
    local itemHeight = 50
    local visibleCount = 9

    for i = 1, math.min(visibleCount, #cards - state.cardScroll) do
        local idx = i + state.cardScroll
        local itemY = startY + (i - 1) * itemHeight

        if x >= 50 and x <= 650 and y >= itemY and y <= itemY + itemHeight - 5 then
            addCard(cards[idx])
            return
        end
    end
end

local function handleUpgradeClick(x, y)
    -- Back button
    if x >= 50 and x <= 200 and y >= 650 and y <= 690 then
        state.mode = "cards"
        return
    end

    -- Save button
    if x >= 500 and x <= 700 and y >= 650 and y <= 690 then
        state.mode = "save"
        state.deckName = "CustomDeck"
        return
    end

    -- Card list
    local startY = 110
    local itemHeight = 60
    local visibleCount = 8

    for i = 1, math.min(visibleCount, #state.selectedCards - state.upgradeScroll) do
        local idx = i + state.upgradeScroll
        local itemY = startY + (i - 1) * itemHeight

        if x >= 50 and x <= 650 and y >= itemY and y <= itemY + itemHeight - 5 then
            toggleUpgrade(idx)
            return
        end
    end
end

local function handleSaveClick(x, y)
    -- Back button
    if x >= 50 and x <= 200 and y >= 500 and y <= 540 then
        state.mode = "upgrades"
        return
    end

    -- Save & Exit button
    if x >= 250 and x <= 450 and y >= 500 and y <= 540 then
        if state.deckName ~= "" then
            saveDeck()
            if _G.returnToMenu then
                _G.returnToMenu()
            end
        end
        return
    end

    -- Save & Test button
    if x >= 500 and x <= 700 and y >= 500 and y <= 540 then
        if state.deckName ~= "" then
            saveDeck()
            loadSavedDecks()
            state.mode = "testcombat"
            state.enemyList = getAllEnemies()
            state.selectedDeckIndex = #state.savedDecks  -- Auto-select the deck we just saved
        end
        return
    end
end

local function handleTestCombatClick(x, y)
    -- Back button
    if x >= 50 and x <= 250 and y >= 650 and y <= 690 then
        if _G.returnToMenu then
            _G.returnToMenu()
        end
        return
    end

    -- Start combat button
    if x >= 500 and x <= 700 and y >= 650 and y <= 690 then
        if state.selectedDeckIndex and state.selectedEnemyIndex then
            startTestCombat()
        end
        return
    end

    -- Deck list
    local startY = 160
    for i, deckName in ipairs(state.savedDecks) do
        local itemY = startY + (i - 1) * 40
        if x >= 50 and x <= 350 and y >= itemY and y <= itemY + 35 then
            state.selectedDeckIndex = i
            return
        end
    end

    -- Enemy list
    startY = 160
    for i, enemy in ipairs(state.enemyList) do
        local itemY = startY + (i - 1) * 40
        if x >= 400 and x <= 700 and y >= itemY and y <= itemY + 35 then
            state.selectedEnemyIndex = i
            return
        end
    end
end

function saveDeck()
    -- Build deck data
    local relicIds = {}
    for _, relic in ipairs(state.selectedRelics) do
        table.insert(relicIds, relic.id)
    end

    local cards = {}
    for _, cardInfo in ipairs(state.selectedCards) do
        table.insert(cards, {
            id = cardInfo.cardDef.id,
            upgraded = cardInfo.upgraded
        })
    end

    local deckData = {
        name = state.deckName,
        character = state.selectedCharacter,
        relics = relicIds,
        cards = cards
    }

    DeckSerializer.save(deckData, state.deckName)
end

function startTestCombat()
    if not state.selectedDeckIndex or not state.selectedEnemyIndex then
        return
    end

    -- Load deck
    local deckName = state.savedDecks[state.selectedDeckIndex]
    local deckData = DeckSerializer.load(deckName)

    -- Build master deck
    local masterDeck = DeckSerializer.deckDataToMasterDeck(deckData, Cards)

    -- Build relics list
    local relics = {}
    for _, relicId in ipairs(deckData.relics) do
        for key, relic in pairs(Relics) do
            if relic.id == relicId then
                table.insert(relics, relic)
                break
            end
        end
    end

    -- Get enemy
    local enemyData = state.enemyList[state.selectedEnemyIndex].data

    -- Call the global function to start combat
    if _G.startTestCombatWithDeck then
        _G.startTestCombatWithDeck(masterDeck, relics, deckData.character, enemyData)
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function DeckbuilderLove.init()
    state = {
        mode = "character",
        selectedCharacter = "IRONCLAD",
        allowAllCards = false,
        selectedRelics = {},
        hoveredRelicIndex = nil,
        relicScroll = 0,
        selectedCards = {},
        hoveredCardIndex = nil,
        cardScroll = 0,
        cardFilter = "ALL",
        hoveredUpgradeCardIndex = nil,
        upgradeScroll = 0,
        deckName = "",
        hoveredSaveButton = nil,
        savedDecks = {},
        selectedDeckIndex = nil,
        hoveredDeckIndex = nil,
        selectedEnemyIndex = 1,
        hoveredEnemyIndex = nil,
        enemyList = {},
    }

    -- Ensure Saved_Decks directory exists
    love.filesystem.createDirectory("Saved_Decks")

    -- Load saved decks for test combat mode
    loadSavedDecks()
end

function DeckbuilderLove.initTestCombat()
    state.mode = "testcombat"
    state.savedDecks = DeckSerializer.listDecks()
    state.enemyList = getAllEnemies()
    state.selectedDeckIndex = 1
    state.selectedEnemyIndex = 1
end

function DeckbuilderLove.draw()
    if state.mode == "character" then
        drawCharacterSelection()
    elseif state.mode == "relics" then
        drawRelicSelection()
    elseif state.mode == "cards" then
        drawCardSelection()
    elseif state.mode == "upgrades" then
        drawUpgradeSelection()
    elseif state.mode == "save" then
        drawSaveMode()
    elseif state.mode == "testcombat" then
        drawTestCombat()
    end
end

function DeckbuilderLove.update(dt)
    -- Update hover states based on mouse position
    local mx, my = love.mouse.getPosition()

    if state.mode == "relics" then
        local relics = getAllRelics()
        local startY = 100
        local itemHeight = 60
        local visibleCount = 8

        state.hoveredRelicIndex = nil
        for i = 1, math.min(visibleCount, #relics - state.relicScroll) do
            local idx = i + state.relicScroll
            local y = startY + (i - 1) * itemHeight
            if mx >= 50 and mx <= 650 and my >= y and my <= y + itemHeight - 5 then
                state.hoveredRelicIndex = idx
                break
            end
        end
    elseif state.mode == "cards" then
        local cards = getFilteredCards()
        local startY = 130
        local itemHeight = 50
        local visibleCount = 9

        state.hoveredCardIndex = nil
        for i = 1, math.min(visibleCount, #cards - state.cardScroll) do
            local idx = i + state.cardScroll
            local y = startY + (i - 1) * itemHeight
            if mx >= 50 and mx <= 650 and my >= y and my <= y + itemHeight - 5 then
                state.hoveredCardIndex = idx
                break
            end
        end
    elseif state.mode == "upgrades" then
        local startY = 110
        local itemHeight = 60
        local visibleCount = 8

        state.hoveredUpgradeCardIndex = nil
        for i = 1, math.min(visibleCount, #state.selectedCards - state.upgradeScroll) do
            local idx = i + state.upgradeScroll
            local y = startY + (i - 1) * itemHeight
            if mx >= 50 and mx <= 650 and my >= y and my <= y + itemHeight - 5 then
                state.hoveredUpgradeCardIndex = idx
                break
            end
        end
    elseif state.mode == "save" then
        state.hoveredSaveButton = nil
        if mx >= 250 and mx <= 450 and my >= 500 and my <= 540 then
            state.hoveredSaveButton = 1
        elseif mx >= 500 and mx <= 700 and my >= 500 and my <= 540 then
            state.hoveredSaveButton = 2
        end
    elseif state.mode == "testcombat" then
        -- Update hover for decks
        state.hoveredDeckIndex = nil
        local startY = 160
        for i, _ in ipairs(state.savedDecks) do
            local y = startY + (i - 1) * 40
            if mx >= 50 and mx <= 350 and my >= y and my <= y + 35 then
                state.hoveredDeckIndex = i
                break
            end
        end

        -- Update hover for enemies
        state.hoveredEnemyIndex = nil
        startY = 160
        for i, _ in ipairs(state.enemyList) do
            local y = startY + (i - 1) * 40
            if mx >= 400 and mx <= 700 and my >= y and my <= y + 35 then
                state.hoveredEnemyIndex = i
                break
            end
        end
    end
end

function DeckbuilderLove.mousepressed(x, y, button)
    if button ~= 1 then return end

    if state.mode == "character" then
        handleCharacterClick(x, y)
    elseif state.mode == "relics" then
        handleRelicClick(x, y)
    elseif state.mode == "cards" then
        handleCardClick(x, y)
    elseif state.mode == "upgrades" then
        handleUpgradeClick(x, y)
    elseif state.mode == "save" then
        handleSaveClick(x, y)
    elseif state.mode == "testcombat" then
        handleTestCombatClick(x, y)
    end
end

function DeckbuilderLove.wheelmoved(x, y)
    if state.mode == "relics" then
        local relics = getAllRelics()
        local visibleCount = 8
        local maxScroll = math.max(0, #relics - visibleCount)
        state.relicScroll = math.max(0, math.min(maxScroll, state.relicScroll - y))
    elseif state.mode == "cards" then
        local cards = getFilteredCards()
        local visibleCount = 9
        local maxScroll = math.max(0, #cards - visibleCount)
        state.cardScroll = math.max(0, math.min(maxScroll, state.cardScroll - y))
    elseif state.mode == "upgrades" then
        local visibleCount = 8
        local maxScroll = math.max(0, #state.selectedCards - visibleCount)
        state.upgradeScroll = math.max(0, math.min(maxScroll, state.upgradeScroll - y))
    end
end

function DeckbuilderLove.textinput(text)
    if state.mode == "save" then
        -- Allow alphanumeric and underscores only
        if text:match("^[%w_]$") then
            state.deckName = state.deckName .. text
        end
    end
end

function DeckbuilderLove.keypressed(key)
    if key == "escape" then
        if _G.returnToMenu then
            _G.returnToMenu()
        end
    elseif key == "backspace" and state.mode == "save" then
        state.deckName = state.deckName:sub(1, -2)
    end
end

return DeckbuilderLove
