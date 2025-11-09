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
--
-- EXAMPLES:
--   -- Enemy targeting (Strike, Bash, etc.)
--   contextProvider = "enemy"
--
--   -- Select 1 card from combat deck, no filter (Setup)
--   contextProvider = {
--       count = {min = 1, max = 1}
--   }
--
--   -- Select 0-3 Skills from combat deck (Eviscerate-like)
--   contextProvider = {
--       count = {min = 0, max = 3},
--       filter = function(world, player, card, candidateCard)
--           return candidateCard.type == "SKILL"
--       end
--   }
--
--   -- Select cards from master deck (for permanent deck modification)
--   contextProvider = {
--       source = "master",
--       count = {min = 1, max = 1}
--   }
--
--   -- Dynamic count based on energy (Forethought+)
--   contextProvider = {
--       count = function(world, player, card)
--           return {min = 0, max = 999}
--       end
--   }

local ContextProvider = {}

local Utils = require("utils")

-- Determines the type of context a card needs
-- Returns: "none", "enemy", or "cards"
function ContextProvider.getContextType(card)
    if not card.contextProvider then
        return "none"  -- No context needed (Defend, Corruption, etc.)
    elseif card.contextProvider == "enemy" then
        return "enemy"  -- Enemy targeting (Strike, Bash, etc.)
    elseif type(card.contextProvider) == "table" then
        return "cards"  -- Card selection (Setup, Eviscerate, etc.)
    else
        return "none"  -- Unknown/invalid contextProvider
    end
end

-- Gets selection info for UI display (used by CombatEngine)
-- Returns table with: {type, source?, count?}
function ContextProvider.getSelectionInfo(card)
    if not card.contextProvider then
        return {type = "none"}

    elseif card.contextProvider == "enemy" then
        return {type = "enemy"}

    elseif type(card.contextProvider) == "table" then
        local provider = card.contextProvider

        -- Extract count (handle both static and dynamic)
        local count = provider.count or {min = 1, max = 1}
        if type(count) == "function" then
            -- Can't call function without world/player, use default
            count = {min = 1, max = 1}
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

-- Gets all valid cards that can be selected (used by UI before player choice)
-- This applies the filter but doesn't enforce count constraints
-- Returns: array of valid cards (empty if not a card selection context)
function ContextProvider.getValidCards(world, player, card)
    -- Only card selection contexts return cards
    if type(card.contextProvider) ~= "table" then
        return {}
    end

    local provider = card.contextProvider

    -- STEP 1: Determine which deck to select from
    local source = provider.source or "combat"
    local sourceDeck
    if source == "master" then
        -- Select from masterDeck (permanent deck, for deck modification cards)
        sourceDeck = player.masterDeck
    else
        -- Select from combatDeck (temporary, for in-combat selection)
        -- Falls back to masterDeck if not in combat
        sourceDeck = player.combatDeck or player.masterDeck
    end

    -- STEP 2: Filter cards from the deck
    local validCards = {}
    for _, candidateCard in ipairs(sourceDeck) do
        -- Always exclude the card being played (can't target self)
        if candidateCard ~= card then
            -- Apply custom filter if provided
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

-- Main execute function - collects and returns context for a card
-- Returns: nil, enemy entity, or array of cards (depending on contextProvider)
function ContextProvider.execute(world, player, card)
    if not card.contextProvider then
        -- NO CONTEXT (Defend, Corruption, Bloodletting, etc.)
        return nil

    elseif card.contextProvider == "enemy" then
        -- ENEMY TARGETING (Strike, Bash, Catalyst, etc.)
        -- Auto-select first alive enemy (in real game, player would choose)
        if world.enemies then
            for _, enemy in ipairs(world.enemies) do
                if enemy.hp > 0 then
                    return enemy
                end
            end
            return world.enemies[1]  -- Fallback to first enemy even if dead
        end
        return world.enemy  -- Single enemy format (legacy)

    elseif type(card.contextProvider) == "table" then
        -- CARD SELECTION (Setup, Eviscerate, etc.)
        return ContextProvider.executeCardSelection(world, player, card)

    else
        -- Unknown/invalid contextProvider
        return nil
    end
end

-- Executes card selection logic
-- Returns: array of selected cards (or nil if constraints not met)
function ContextProvider.executeCardSelection(world, player, card)
    local provider = card.contextProvider

    -- STEP 1: Get count constraints (min/max cards to select)
    local count
    if type(provider.count) == "function" then
        -- Dynamic count (e.g., based on energy, hand size, etc.)
        count = provider.count(world, player, card)
    else
        -- Static count (default: exactly 1 card)
        count = provider.count or {min = 1, max = 1}
    end

    -- STEP 2: Get all valid cards that pass the filter
    local validCards = ContextProvider.getValidCards(world, player, card)

    -- STEP 3: Auto-select cards (in real game, player would choose)
    -- Currently just takes first N cards
    local selectedCards = {}
    for i = 1, math.min(count.max, #validCards) do
        table.insert(selectedCards, validCards[i])
    end

    -- STEP 4: Validate minimum count requirement
    if #selectedCards < count.min then
        -- Not enough valid cards available
        table.insert(world.log, "Not enough valid cards for " .. card.name .. " (need " .. count.min .. ", found " .. #selectedCards .. ")")
        return nil  -- Signal failure - card cannot be played
    end

    -- Return array of selected cards (always an array, even if empty or single card)
    return selectedCards
end

return ContextProvider
