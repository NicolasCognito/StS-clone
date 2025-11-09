-- UTILITY FUNCTIONS
-- Reusable helper functions for copying cards, decks, and other common operations

local Utils = {}

-- Shallow copy function for cards (copies top-level properties only)
-- Used for creating cards from templates
function Utils.copyCard(cardTemplate)
    local copy = {}
    for k, v in pairs(cardTemplate) do
        copy[k] = v
    end
    -- Initialize state to DECK
    copy.state = "DECK"
    return copy
end

-- Deep copy function for cards (preserves all properties)
-- Used for duplicating existing cards with nested tables
function Utils.deepCopyCard(card)
    local copy = {}
    for k, v in pairs(card) do
        if type(v) == "table" then
            -- Deep copy tables (except functions)
            copy[k] = {}
            for innerK, innerV in pairs(v) do
                copy[k][innerK] = innerV
            end
        else
            copy[k] = v
        end
    end
    -- Reset state to DECK for battle start
    copy.state = "DECK"
    return copy
end

-- Deep copy an entire deck
-- Used when copying globalDeck to player.cards for battle
function Utils.deepCopyDeck(deck)
    local copy = {}
    for i, card in ipairs(deck) do
        table.insert(copy, Utils.deepCopyCard(card))
    end
    return copy
end

return Utils
