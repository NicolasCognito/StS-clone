-- CARD LOADER UTILITY FOR TESTS
-- Provides helper functions for loading and cloning cards in test environments

local Utils = require("utils")
local Cards = require("Data.cards")

local CardLoader = {}

-- Clone a card by ID
-- Returns a copy of the card template with proper initialization
function CardLoader.cloneCard(cardId)
    -- Find the card in the Cards module
    local card = Cards[cardId]
    if not card then
        error("Card not found: " .. cardId)
    end

    -- Use the standard card template copy function
    return Utils.copyCardTemplate(card)
end

-- Alias for consistency with some test expectations
CardLoader.getCard = CardLoader.cloneCard

return CardLoader
