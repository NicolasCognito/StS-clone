-- CONTEXT PROVIDER PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card that needs context
--
-- CONTEXT SYSTEM (card.contextProvider):
--
-- 1. ENEMY TARGETING:
--    contextProvider = "enemy"
--    Returns: enemy entity
--
-- 2. CARD SELECTION:
--    contextProvider = {
--        source = "combat" or "master",  -- which deck to select from (default: "combat")
--        count = {min = 1, max = 1} or function(world, player, card) -> {min, max},
--        filter = function(world, player, card, candidateCard) -> boolean
--    }
--    Returns: array of selected cards
--
--    Deck Sources:
--      - "combat": player.combatDeck (temporary, during combat only)
--      - "master": player.masterDeck (permanent deck, persists across combats)
--
-- 3. NO CONTEXT:
--    contextProvider = nil or not present
--    Returns: nil

local ContextProvider = {}

local Utils = require("utils")

function ContextProvider.getContextType(card)
    if not card.contextProvider then
        return "none"
    elseif card.contextProvider == "enemy" then
        return "enemy"
    elseif type(card.contextProvider) == "table" then
        return "cards"
    else
        return "none"
    end
end

-- Helper to get selection info for UI (used by CombatEngine)
function ContextProvider.getSelectionInfo(card)
    if not card.contextProvider then
        return {type = "none"}
    elseif card.contextProvider == "enemy" then
        return {type = "enemy"}
    elseif type(card.contextProvider) == "table" then
        local provider = card.contextProvider
        local count = provider.count or {min = 1, max = 1}
        if type(count) == "function" then
            count = {min = 1, max = 1}  -- Can't determine without world/player context
        end
        return {
            type = "cards",
            source = provider.source or "combat",
            count = count
        }
    else
        return {type = "none"}
    end
end

-- Helper to get valid cards for selection (used by UI before player selects)
function ContextProvider.getValidCards(world, player, card)
    if type(card.contextProvider) ~= "table" then
        return {}
    end

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

function ContextProvider.execute(world, player, card)
    if not card.contextProvider then
        -- NO CONTEXT
        return nil
    elseif card.contextProvider == "enemy" then
        -- ENEMY TARGETING
        if world.enemies then
            for _, enemy in ipairs(world.enemies) do
                if enemy.hp > 0 then
                    return enemy
                end
            end
            return world.enemies[1]
        end
        return world.enemy
    elseif type(card.contextProvider) == "table" then
        -- CARD SELECTION
        return ContextProvider.executeCardSelection(world, player, card)
    else
        return nil
    end
end

-- CARD SELECTION SYSTEM
function ContextProvider.executeCardSelection(world, player, card)
    local provider = card.contextProvider

    -- Get count constraints
    local count
    if type(provider.count) == "function" then
        count = provider.count(world, player, card)
    else
        count = provider.count or {min = 1, max = 1}
    end

    -- Get valid cards
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
