-- DeckSerializer: Save and load deck configurations to/from JSON files

local JSON = require("json")

local DeckSerializer = {}

-- Save a deck configuration to a JSON file
-- deckData format:
-- {
--   name = "My Deck",
--   character = "IRONCLAD",
--   relics = {"Burning_Blood", "Vajra"},
--   cards = {
--     {id = "Strike_R", upgraded = false},
--     {id = "Defend_R", upgraded = true},
--   }
-- }
function DeckSerializer.save(deckData, filename)
    if not filename:match("%.json$") then
        filename = filename .. ".json"
    end

    local filepath = "Saved_Decks/" .. filename

    -- Validate deck data
    assert(deckData.name, "Deck must have a name")
    assert(deckData.character, "Deck must have a character")
    assert(deckData.relics, "Deck must have relics array")
    assert(deckData.cards, "Deck must have cards array")

    -- Encode to JSON
    local json_str = JSON.encode(deckData)

    -- Write to file using love.filesystem
    local success, err = love.filesystem.write(filepath, json_str)
    if not success then
        error("Failed to save deck: " .. tostring(err))
    end

    return filepath
end

-- Load a deck configuration from a JSON file
function DeckSerializer.load(filename)
    if not filename:match("%.json$") then
        filename = filename .. ".json"
    end

    local filepath = "Saved_Decks/" .. filename

    -- Read file using love.filesystem
    local content, err = love.filesystem.read(filepath)
    if not content then
        error("Failed to load deck: " .. tostring(err))
    end

    -- Decode JSON
    local deckData = JSON.decode(content)

    -- Validate
    assert(deckData.name, "Invalid deck: missing name")
    assert(deckData.character, "Invalid deck: missing character")
    assert(deckData.relics, "Invalid deck: missing relics")
    assert(deckData.cards, "Invalid deck: missing cards")

    return deckData
end

-- List all saved decks
function DeckSerializer.listDecks()
    local decks = {}

    -- Use love.filesystem to list files (cross-platform)
    local items = love.filesystem.getDirectoryItems("Saved_Decks")
    for _, filename in ipairs(items) do
        -- Only include .json files
        if filename:match("%.json$") then
            -- Extract just the filename without extension
            local name = filename:match("(.+)%.json$")
            if name then
                table.insert(decks, name)
            end
        end
    end

    return decks
end

-- Delete a saved deck
function DeckSerializer.delete(filename)
    if not filename:match("%.json$") then
        filename = filename .. ".json"
    end

    local filepath = "Saved_Decks/" .. filename
    love.filesystem.remove(filepath)
end

-- Convert a deck configuration into a masterDeck array for game use
-- This takes the saved deck format and creates actual card instances
function DeckSerializer.deckDataToMasterDeck(deckData, cardsDatabase)
    local masterDeck = {}

    for _, cardInfo in ipairs(deckData.cards) do
        -- Find the card in the database
        local cardDef = cardsDatabase[cardInfo.id]
        if cardDef then
            -- Create a copy of the card
            local card = {}
            for k, v in pairs(cardDef) do
                card[k] = v
            end

            -- Apply upgrade if needed
            if cardInfo.upgraded and card.onUpgrade then
                card:onUpgrade()
            end

            table.insert(masterDeck, card)
        else
            print("Warning: Card not found: " .. cardInfo.id)
        end
    end

    return masterDeck
end

-- Convert a masterDeck array into deck data format for saving
function DeckSerializer.masterDeckToDeckData(masterDeck, character, relics, name)
    local cards = {}

    for _, card in ipairs(masterDeck) do
        table.insert(cards, {
            id = card.id,
            upgraded = card.upgraded or false
        })
    end

    return {
        name = name or "Unnamed Deck",
        character = character or "IRONCLAD",
        relics = relics or {},
        cards = cards
    }
end

return DeckSerializer
