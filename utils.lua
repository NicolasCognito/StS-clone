-- UTILITY FUNCTIONS
-- Reusable helper functions for copying cards, decks, and other common operations

local Utils = {}

-- Used for legacy flows where cards entered combat-ready decks immediately
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

-- Template copy helpers (no combat state) for persistent world decks/enemies
function Utils.copyCardTemplate(cardTemplate)
    local copy = {}
    for k, v in pairs(cardTemplate) do
        copy[k] = v
    end
    return copy
end

function Utils.copyEnemyTemplate(enemyTemplate)
    local copy = {}
    for k, v in pairs(enemyTemplate) do
        copy[k] = v
    end
    return copy
end

-- Check if player has a specific power
-- Used throughout pipelines to check for power effects
function Utils.hasPower(player, powerId)
    if not player.powers then return false end
    for _, power in ipairs(player.powers) do
        if power.id == powerId then
            return true
        end
    end
    return false
end

-- Check if a tag exists in a tags array
-- Used for checking effect tags like "ignoreBlock", "costsZeroThisTurn", etc.
function Utils.hasTag(tags, tagName)
    if not tags then return false end
    for _, tag in ipairs(tags) do
        if tag == tagName then
            return true
        end
    end
    return false
end

-- Get all cards in a specific state
-- States: "DECK", "HAND", "DISCARD_PILE", "EXHAUSTED_PILE"
function Utils.getCardsByState(player, state)
    local cards = {}
    for _, card in ipairs(player.cards) do
        if card.state == state then
            table.insert(cards, card)
        end
    end
    return cards
end

-- Get count of cards in a specific state
-- States: "DECK", "HAND", "DISCARD_PILE", "EXHAUSTED_PILE"
function Utils.getCardCountByState(player, state)
    local count = 0
    for _, card in ipairs(player.cards) do
        if card.state == state then
            count = count + 1
        end
    end
    return count
end

return Utils
