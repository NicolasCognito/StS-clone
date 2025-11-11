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
-- Used when copying masterDeck to combatDeck at battle start
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
    -- Ensure combat state containers exist so tests/pipelines can mutate status immediately
    copy.status = copy.status or {}
    copy.powers = copy.powers or {}
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

-- Check if player has a specific relic
-- Used throughout pipelines to check for relic effects
function Utils.hasRelic(player, relicId)
    if not player.relics then return false end
    for _, relic in ipairs(player.relics) do
        if relic.id == relicId then
            return true
        end
    end
    return false
end

-- Get a specific relic from player's relics
-- Returns the relic object if found, nil otherwise
-- Useful for accessing relic properties like triggerCount, damageMultiplier, etc.
function Utils.getRelic(player, relicId)
    if not player.relics then return nil end
    for _, relic in ipairs(player.relics) do
        if relic.id == relicId then
            return relic
        end
    end
    return nil
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
-- deck: the deck to search (typically player.combatDeck during combat, player.masterDeck outside)
function Utils.getCardsByState(deck, state)
    local cards = {}
    for _, card in ipairs(deck) do
        if card.state == state then
            table.insert(cards, card)
        end
    end
    return cards
end

-- Get count of cards in a specific state
-- States: "DECK", "HAND", "DISCARD_PILE", "EXHAUSTED_PILE"
-- deck: the deck to search (typically player.combatDeck during combat, player.masterDeck outside)
function Utils.getCardCountByState(deck, state)
    local count = 0
    for _, card in ipairs(deck) do
        if card.state == state then
            count = count + 1
        end
    end
    return count
end

-- Move a specific card reference to the front of the supplied deck table
-- Used for effects that place cards on top of the draw pile (Headbutt, Recycle, etc.)
function Utils.moveCardToDeckTop(deck, card)
    if not deck or not card then
        return false
    end

    local index = nil
    for i, candidate in ipairs(deck) do
        if candidate == card then
            index = i
            break
        end
    end

    if not index then
        return false
    end

    table.remove(deck, index)
    table.insert(deck, 1, card)
    return true
end

function Utils.log(world, message)
    if not message then
        return
    end

    if world and world.log then
        table.insert(world.log, message)
    else
        print(message)
    end
end

return Utils
