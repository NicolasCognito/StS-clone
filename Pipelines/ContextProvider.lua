-- CONTEXT PROVIDER PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card that needs context (optional, for filter functions)
-- contextProvider: the context configuration
--
-- CONTEXT SYSTEM:
--
-- 1. ENEMY TARGETING:
--    contextProvider = {type = "enemy", stability = "stable"}
--    Returns: enemy entity
--
-- 2. CARD SELECTION:
--    contextProvider = {
--        type = "cards",
--        stability = "stable" or "temp",
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
--    Stability:
--      - "stable": Persists across duplications (e.g., enemy target stays same)
--      - "temp": Re-collected on each duplication (e.g., card discard changes each time)
--
-- 3. NO CONTEXT:
--    contextProvider = nil or not present
--    Returns: nil
--
-- EXAMPLES:
--   -- Enemy targeting (Strike, Bash, etc.)
--   contextProvider = {type = "enemy", stability = "stable"}
--
--   -- Select 1 card from combat deck, no filter (Setup)
--   contextProvider = {
--       type = "cards",
--       stability = "temp",
--       count = {min = 1, max = 1}
--   }
--
--   -- Select 0-3 Skills from combat deck (Eviscerate-like)
--   contextProvider = {
--       type = "cards",
--       stability = "temp",
--       count = {min = 0, max = 3},
--       filter = function(world, player, card, candidateCard)
--           return candidateCard.type == "SKILL"
--       end
--   }
--
--   -- Select cards from master deck (for permanent deck modification)
--   contextProvider = {
--       type = "cards",
--       stability = "temp",
--       source = "master",
--       count = {min = 1, max = 1}
--   }
--
--   -- Dynamic count based on energy (Forethought+)
--   contextProvider = {
--       type = "cards",
--       stability = "temp",
--       count = function(world, player, card)
--           return {min = 0, max = 999}
--       end
--   }

local ContextProvider = {}

local Utils = require("utils")

-- Determines the type of context needed
-- Returns: "none", "enemy", or "cards"
-- contextProvider: the context configuration
function ContextProvider.getContextType(contextProvider)
    if not contextProvider then
        return "none"  -- No context needed
    elseif type(contextProvider) == "table" then
        return contextProvider.type or "none"
    else
        return "none"  -- Unknown/invalid contextProvider
    end
end

-- Gets selection info for UI display (used by CombatEngine)
-- Returns table with: {type, source?, count?, stability?}
-- contextProvider: the context configuration
function ContextProvider.getSelectionInfo(contextProvider)
    if not contextProvider then
        return {type = "none"}
    end

    local contextType = contextProvider.type
    if contextType == "enemy" then
        return {
            type = "enemy",
            stability = contextProvider.stability or "stable"
        }
    elseif contextType == "cards" then
        -- Extract count (handle both static and dynamic)
        local count = contextProvider.count or {min = 1, max = 1}
        if type(count) == "function" then
            -- Can't call function without world/player, use default
            count = {min = 1, max = 1}
        end

        return {
            type = "cards",
            source = contextProvider.source or "combat",
            count = count,
            stability = contextProvider.stability or "temp"
        }
    else
        return {type = "none"}
    end
end

-- Gets all valid cards that can be selected (used by UI before player choice)
-- This applies the filter but doesn't enforce count constraints
-- Returns: array of valid cards (empty if not a card selection context)
-- card: optional, the card being played (for filter functions and self-exclusion)
-- contextProvider: the context configuration
function ContextProvider.getValidCards(world, player, contextProvider, card)
    -- Only card selection contexts return cards
    if not contextProvider or contextProvider.type ~= "cards" then
        return {}
    end

    -- STEP 1: Determine which deck to select from
    local source = contextProvider.source or "combat"
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
        -- Exclude the card being played (can't target self) if card provided
        if not card or candidateCard ~= card then
            -- Apply custom filter if provided
            local passes = true
            if contextProvider.filter then
                passes = contextProvider.filter(world, player, card, candidateCard)
            end

            if passes then
                table.insert(validCards, candidateCard)
            end
        end
    end

    return validCards
end

-- Main execute function - collects and returns context
-- Returns: nil, enemy entity, or array of cards (depending on contextProvider)
-- card: optional, the card being played (for filter functions and self-exclusion)
-- contextProvider: the context configuration
function ContextProvider.execute(world, player, contextProvider, card)
    if not contextProvider then
        -- NO CONTEXT
        return nil
    end

    local contextType = contextProvider.type
    if contextType == "enemy" then
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

    elseif contextType == "cards" then
        -- CARD SELECTION (Setup, Eviscerate, etc.)
        return ContextProvider.executeCardSelection(world, player, contextProvider, card)

    else
        -- Unknown/invalid contextProvider
        return nil
    end
end

-- Executes card selection logic
-- Returns: array of selected cards (or nil if constraints not met)
-- card: optional, the card being played (for filter functions and error messages)
-- contextProvider: the context configuration
function ContextProvider.executeCardSelection(world, player, contextProvider, card)
    -- STEP 1: Get count constraints (min/max cards to select)
    local count
    if type(contextProvider.count) == "function" then
        -- Dynamic count (e.g., based on energy, hand size, etc.)
        count = contextProvider.count(world, player, card)
    else
        -- Static count (default: exactly 1 card)
        count = contextProvider.count or {min = 1, max = 1}
    end

    -- STEP 2: Get all valid cards that pass the filter
    local validCards = ContextProvider.getValidCards(world, player, contextProvider, card)

    -- STEP 3: Auto-select cards (in real game, player would choose)
    -- Currently just takes first N cards
    local selectedCards = {}
    for i = 1, math.min(count.max, #validCards) do
        table.insert(selectedCards, validCards[i])
    end

    -- STEP 4: Validate minimum count requirement
    if #selectedCards < count.min then
        -- Not enough valid cards available
        local cardName = card and card.name or "card"
        table.insert(world.log, "Not enough valid cards for " .. cardName .. " (need " .. count.min .. ", found " .. #selectedCards .. ")")
        return nil  -- Signal failure - card cannot be played
    end

    -- Return array of selected cards (always an array, even if empty or single card)
    return selectedCards
end

return ContextProvider
