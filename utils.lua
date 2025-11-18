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
    copy.dead = false
    copy.intentHistory = {}  -- Track intent names executed each turn (for AI decision-making)
    return copy
end

-- Check if player has a specific power (now implemented as status effects)
-- Used throughout pipelines to check for power effects
-- Converts PascalCase/camelCase to snake_case for status effect lookup
function Utils.hasPower(player, powerId)
    if not player.status then return false end

    -- Convert powerId to snake_case (e.g., "MasterReality" -> "master_reality")
    local statusKey = powerId:gsub("(%u)", function(c)
        return "_" .. c:lower()
    end):gsub("^_", "")  -- Remove leading underscore

    -- Check if status effect exists and has value > 0
    return player.status[statusKey] and player.status[statusKey] > 0
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

-- Trigger relic hooks for all relics on a combatant
-- Similar to status effect hooks, this allows relics to respond to game events
-- combatant: the character with relics (typically world.player)
-- hookName: the hook to call (e.g., "onDmg", "onTurnStart")
-- ...: additional arguments to pass to the hook
function Utils.triggerRelicHooks(world, combatant, hookName, ...)
    if not combatant or not combatant.relics then return end

    for _, relic in ipairs(combatant.relics) do
        if relic[hookName] then
            relic[hookName](relic, world, combatant, ...)
        end
    end
end

-- Get a random living enemy
-- Returns a random enemy with hp > 0, or nil if no living enemies
-- Used for Lightning orb targeting
function Utils.randomEnemy(world)
    local alive = {}
    for _, enemy in ipairs(world.enemies or {}) do
        if enemy.hp > 0 then
            table.insert(alive, enemy)
        end
    end
    if #alive == 0 then
        return nil
    end
    return alive[math.random(#alive)]
end

-- Get the lowest HP living enemy
-- Returns the enemy with lowest HP > 0, or nil if no living enemies
-- Used for Dark orb targeting
function Utils.lowestHpEnemy(world)
    local lowest = nil
    for _, enemy in ipairs(world.enemies or {}) do
        if enemy.hp > 0 then
            if not lowest or enemy.hp < lowest.hp then
                lowest = enemy
            end
        end
    end
    return lowest
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

-- Shuffle a deck using Fisher-Yates algorithm
-- Modifies the deck in-place
-- Used when starting combat and when reshuffling discard pile into deck
-- world: optional world parameter for testing - if world.NoShuffle is true, skips shuffling
function Utils.shuffleDeck(deck, world)
    if not deck or #deck <= 1 then
        return
    end

    -- Testing flag: skip shuffling for deterministic tests
    if world and world.NoShuffle then
        return
    end

    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
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

-- Check if player has a specific card in hand
-- Used for Normality curse detection
function Utils.hasCardInHand(deck, cardId)
    if not deck then return false end
    for _, card in ipairs(deck) do
        if card.state == "HAND" and card.id == cardId then
            return true
        end
    end
    return false
end

-- Get the card play limit for the current turn
-- Accounts for Velvet Choker (6 cards) and Normality curse (3 cards)
-- Returns the most restrictive limit, or math.huge if unlimited
function Utils.getCardPlayLimit(world, player)
    local limit = math.huge  -- Default: unlimited

    -- Check Velvet Choker (Boss Relic): 6 cards per turn
    if Utils.hasRelic(player, "Velvet_Choker") then
        limit = 6
    end

    -- Check Normality (Curse Card in hand): 3 cards per turn (overrides if lower)
    if player.combatDeck and Utils.hasCardInHand(player.combatDeck, "Normality") then
        limit = math.min(limit, 3)
    end

    return limit
end

-- Check if card matches player's card pool (for AcquireCard filters)
-- Used to determine if a card template should be available for generation
-- tags: optional table with behavior flags
--   influencedByShard: if true, Prismatic Shard relic allows all character cards
-- Returns true if card is in player's available pool
function Utils.matchesPlayerPool(card, player, tags)
    if not card.character then
        return false
    end

    tags = tags or {}

    -- Prismatic Shard: all character cards available
    if tags.influencedByShard and Utils.hasRelic(player, "Prismatic_Shard") then
        return true
    end

    -- Normal: only player's character cards
    return card.character == player.id
end

-- Generate a unique ID for shadow copies and other entities
-- Returns a string like "shadow_12345"
function Utils.generateGUID()
    -- Simple GUID based on current time and random number
    local timestamp = os.time()
    local random = math.random(10000, 99999)
    return string.format("shadow_%d_%d", timestamp, random)
end

-- Decrement a status effect by a given amount
-- If the status reaches 0 or below, it is removed (set to nil)
-- target: the character (player or enemy) with the status
-- statusKey: the status effect key (e.g., "vulnerable", "poison")
-- amount: the amount to decrement (default 1)
function Utils.Decrement(target, statusKey, amount)
    amount = amount or 1
    if not target.status or not target.status[statusKey] then
        return
    end

    target.status[statusKey] = target.status[statusKey] - amount
    if target.status[statusKey] <= 0 then
        target.status[statusKey] = nil
    end
end

-- Remove a status effect completely (set to nil)
-- target: the character (player or enemy) with the status
-- statusKey: the status effect key (e.g., "blur", "slow")
function Utils.WoreOff(target, statusKey)
    if not target.status then
        return
    end
    target.status[statusKey] = nil
end

return Utils
