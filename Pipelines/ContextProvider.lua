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
-- - "enemy": single enemy target (Strike, Bash, etc.) - returns enemy entity
-- - "cards_in_hand": cards from hand - returns array of cards
-- - "cards_in_discard": cards from discard pile - returns array of cards
-- - "cards_in_deck": cards from deck - returns array of cards
--
-- Card Selection Count (for card context types):
-- - card.minCards: minimum number of cards required (default: 1)
-- - card.maxCards: maximum number of cards allowed (default: 1)
-- - Examples:
--   - Setup: minCards=1, maxCards=1 (exactly 1 card)
--   - Forethought+: minCards=0, maxCards=999 (any number)
--   - Eviscerate: minCards=1, maxCards=3 (1 to 3 cards)
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
        -- Return the first alive enemy as default
        -- (Engine.playGame handles explicit user targeting, passing enemy to PlayCard.execute)
        -- This code path is used for automated/non-interactive card execution
        for _, enemy in ipairs(world.enemies) do
            if enemy.hp > 0 then
                return enemy
            end
        end
        table.insert(world.log, "No alive enemies to target!")
        return nil

    elseif contextType == "cards_in_hand" or contextType == "cards_in_discard" or contextType == "cards_in_deck" then
        -- Card selection contexts - always return array
        local state = contextType == "cards_in_hand" and "HAND"
                   or contextType == "cards_in_discard" and "DISCARD_PILE"
                   or "DECK"

        local allCards = getCardsByState(player, state)
        local validCards = {}

        -- Exclude the card being played (if selecting from hand)
        for _, availableCard in ipairs(allCards) do
            if availableCard ~= card then
                table.insert(validCards, availableCard)
            end
        end

        -- Get min/max constraints (defaults: 1 card)
        local minCards = card.minCards or 1
        local maxCards = card.maxCards or 1

        -- For now, just return up to maxCards available cards
        -- In a real game, this would prompt the player to select
        local selectedCards = {}
        for i = 1, math.min(maxCards, #validCards) do
            table.insert(selectedCards, validCards[i])
        end

        -- Validate we have enough cards
        if #selectedCards < minCards then
            table.insert(world.log, "Not enough cards available for " .. card.name .. " (need " .. minCards .. ", found " .. #selectedCards .. ")")
            return nil  -- Signal failure
        end

        return selectedCards  -- Always return array (even if empty or single card)

    else
        -- Unknown context type
        table.insert(world.log, "Unknown context type: " .. contextType)
        return nil
    end
end

return ContextProvider
