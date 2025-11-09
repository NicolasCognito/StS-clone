-- CONTEXT PROVIDER PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card that needs context
--
-- Handles:
-- - Determines what type of context a card needs
-- - Collects appropriate context and returns it to card.onPlay
--
-- NEW FLEXIBLE SYSTEM (card.contextProvider):
-- Cards can define flexible card selection via contextProvider table:
--   contextProvider = {
--     source = "combat" or "master",  -- which deck to select from (default: "combat")
--     count = {min = 1, max = 1} or function(world, player, card) -> {min, max},
--     filter = function(world, player, card, candidateCard) -> boolean
--   }
--
-- Deck Sources:
--   - "combat": player.combatDeck (temporary, during combat only)
--   - "master": player.masterDeck (permanent deck, persists across combats)
--
-- BACKWARDS COMPATIBILITY:
-- 1. Legacy contextType strings still supported:
--    - "none": no context needed
--    - "enemy": single enemy target
--    - "cards_in_hand", "cards_in_discard", "cards_in_deck": card selection from specific states
-- 2. If no contextType/contextProvider, falls back to card.Targeted:
--    - Targeted = 1 → "enemy"
--    - Targeted = 0 → "none"

local ContextProvider = {}

local Utils = require("utils")

function ContextProvider.getContextType(card)
    -- NEW FLEXIBLE SYSTEM: Check for contextProvider
    if card.contextProvider then
        return "cards"  -- Indicates flexible card selection
    end

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

-- Helper to get selection info for UI (used by CombatEngine)
function ContextProvider.getSelectionInfo(card)
    if card.contextProvider then
        local provider = card.contextProvider
        local count = provider.count or {min = 1, max = 1}
        if type(count) == "function" then
            -- Can't determine count without world/player context
            count = {min = 1, max = 1}
        end
        return {
            type = "cards",
            source = provider.source or "combat",
            count = count
        }
    end

    -- Legacy system
    local contextType = card.contextType or (card.Targeted == 1 and "enemy" or "none")
    if contextType == "enemy" then
        return {type = "enemy"}
    elseif contextType == "cards_in_hand" or contextType == "cards_in_discard" or contextType == "cards_in_deck" then
        return {
            type = "cards",
            state = contextType == "cards_in_hand" and "HAND"
                 or contextType == "cards_in_discard" and "DISCARD_PILE"
                 or "DECK",
            count = {min = card.minCards or 1, max = card.maxCards or 1}
        }
    end

    return {type = "none"}
end

function ContextProvider.execute(world, player, card)
    -- NEW FLEXIBLE SYSTEM: Check for contextProvider first
    if card.contextProvider then
        return ContextProvider.executeFlexible(world, player, card)
    end

    -- BACKWARDS COMPATIBILITY: Legacy contextType system
    local contextType = ContextProvider.getContextType(card)

    if contextType == "none" then
        -- No context needed
        return nil

    elseif contextType == "enemy" then
        if world.enemies then
            for _, enemy in ipairs(world.enemies) do
                if enemy.hp > 0 then
                    return enemy
                end
            end
            return world.enemies[1]
        end

        return world.enemy

    elseif contextType == "cards_in_hand" or contextType == "cards_in_discard" or contextType == "cards_in_deck" then
        -- Card selection contexts - always return array
        local state = contextType == "cards_in_hand" and "HAND"
                   or contextType == "cards_in_discard" and "DISCARD_PILE"
                   or "DECK"

        local sourceDeck = player.combatDeck or player.masterDeck
        local allCards = Utils.getCardsByState(sourceDeck, state)
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

-- Helper to get valid cards for selection (used by UI before player selects)
function ContextProvider.getValidCards(world, player, card)
    if card.contextProvider then
        local provider = card.contextProvider

        -- Determine source deck
        local source = provider.source or "combat"
        local sourceDeck
        if source == "master" then
            sourceDeck = player.masterDeck
        else
            sourceDeck = player.combatDeck or player.masterDeck
        end

        -- Apply filter to all cards in deck
        local validCards = {}
        for _, candidateCard in ipairs(sourceDeck) do
            -- Exclude the card being played
            if candidateCard ~= card then
                -- Apply filter if provided
                local passes = true
                if provider.filter then
                    passes = provider.filter(world, player, card, candidateCard)
                end
                if passes then
                    table.insert(validCards, candidateCard)
                end
            end
        end

        return validCards
    end

    -- Legacy system: return all cards in the specified state
    local contextType = card.contextType
    if contextType == "cards_in_hand" or contextType == "cards_in_discard" or contextType == "cards_in_deck" then
        local state = contextType == "cards_in_hand" and "HAND"
                   or contextType == "cards_in_discard" and "DISCARD_PILE"
                   or "DECK"
        local sourceDeck = player.combatDeck or player.masterDeck
        local allCards = Utils.getCardsByState(sourceDeck, state)
        local validCards = {}
        for _, availableCard in ipairs(allCards) do
            if availableCard ~= card then
                table.insert(validCards, availableCard)
            end
        end
        return validCards
    end

    return {}
end

-- NEW FLEXIBLE CARD SELECTION SYSTEM
function ContextProvider.executeFlexible(world, player, card)
    local provider = card.contextProvider

    -- Get count constraints
    local count
    if type(provider.count) == "function" then
        count = provider.count(world, player, card)
    else
        count = provider.count or {min = 1, max = 1}
    end

    -- Get valid cards (reuses helper for consistency)
    local validCards = ContextProvider.getValidCards(world, player, card)

    -- Select up to maxCards
    local selectedCards = {}
    for i = 1, math.min(count.max, #validCards) do
        table.insert(selectedCards, validCards[i])
    end

    -- Validate minimum count
    if #selectedCards < count.min then
        table.insert(world.log, "Not enough valid cards for " .. card.name .. " (need " .. count.min .. ", found " .. #selectedCards .. ")")
        return nil
    end

    return selectedCards
end

return ContextProvider
