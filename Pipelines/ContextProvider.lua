-- CONTEXT PROVIDER PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card that needs context
--
-- Handles:
-- - Determines what type of context a card needs
-- - Collects appropriate context based on card.contextType
-- - Returns context to be passed to card.onPlay
--
-- Context Types:
-- - "none": no context needed (Defend, etc.)
-- - "enemy": single enemy target (Strike, Bash, etc.)
-- - "card_in_hand": single card from hand (Setup, Forethought)
-- - "cards_in_hand": multiple cards from hand (Forethought+)
-- - "card_in_discard": single card from discard pile
-- - "card_in_deck": single card from deck
--
-- For backwards compatibility:
-- - If contextType not specified, falls back to card.Targeted
--   - Targeted = 1 → "enemy"
--   - Targeted = 0 → "none"

local ContextProvider = {}

-- Helper to get cards by state
local function getCardsByState(player, state)
    local cards = {}
    for _, card in ipairs(player.cards) do
        if card.state == state then
            table.insert(cards, card)
        end
    end
    return cards
end

function ContextProvider.getContextType(card)
    -- If card has explicit contextType, use it
    if card.contextType then
        return card.contextType
    end

    -- Backwards compatibility: use Targeted field
    if card.Targeted == 1 then
        return "enemy"
    else
        return "none"
    end
end

function ContextProvider.execute(world, player, card)
    local contextType = ContextProvider.getContextType(card)

    if contextType == "none" then
        -- No context needed
        return nil

    elseif contextType == "enemy" then
        -- Single enemy target
        -- For now, just return the enemy from world
        -- In a real game, this would prompt player to select from multiple enemies
        return world.enemy

    elseif contextType == "card_in_hand" then
        -- Single card from hand
        -- For now, just return the first card in hand (excluding the card being played)
        -- In a real game, this would prompt player to select
        local handCards = getCardsByState(player, "HAND")
        for _, handCard in ipairs(handCards) do
            if handCard ~= card then
                return handCard  -- Return first card that isn't the one being played
            end
        end
        return nil  -- No valid cards in hand

    elseif contextType == "cards_in_hand" then
        -- Multiple cards from hand (for Forethought+)
        -- For now, return all cards in hand (excluding the card being played)
        -- In a real game, this would prompt player to select multiple cards
        local handCards = getCardsByState(player, "HAND")
        local validCards = {}
        for _, handCard in ipairs(handCards) do
            if handCard ~= card then
                table.insert(validCards, handCard)
            end
        end
        return validCards

    elseif contextType == "card_in_discard" then
        -- Single card from discard pile
        local discardCards = getCardsByState(player, "DISCARD_PILE")
        return discardCards[1]  -- Return first card in discard

    elseif contextType == "card_in_deck" then
        -- Single card from deck
        local deckCards = getCardsByState(player, "DECK")
        return deckCards[1]  -- Return first card in deck

    else
        -- Unknown context type
        table.insert(world.log, "Unknown context type: " .. contextType)
        return nil
    end
end

return ContextProvider
