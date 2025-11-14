-- ACQUIRE CARD PIPELINE (REDESIGNED)
-- Handles card acquisition with flexible filtering, destinations, and options
--
-- Usage:
--   AcquireCard.execute(world, player, cardSource, options)
--
-- cardSource:
--   - Card template directly (e.g., Cards.Shiv, Cards.Wound)
--   - Filter specification: {filter = function(world, card) ... end, count = N}
--
-- options: {
--   destination = "HAND" | "DISCARD_PILE" | "DECK" | custom_state_string
--     "HAND": add to hand with state="HAND"
--     "DISCARD_PILE": add with state="DISCARD_PILE"
--     "DECK": insert at position in draw pile (NOT full shuffle!)
--     custom string: set state to that value (e.g., "DRAFT", "NIGHTMARE")
--
--   position = "random" | "top" | "bottom" | number
--     Only applies when destination="DECK"
--     "random": insert at random index [1, deckSize+1] (default)
--     "top": insert at index 1 (top of deck)
--     "bottom": insert at index deckSize+1 (bottom of deck)
--     number: insert at specific index
--
--   tags = {"costsZeroThisTurn", "costsZeroThisCombat", "retain", ...}
--     Applied as card.tagName = 1 for each tag
--
--   targetDeck = "combat" | "master"
--     Defaults: "combat" if in combat, "master" otherwise
--
--   count = 1
--     How many copies of EACH selected card (default 1)
--
--   skipMasterReality = false (for modders)
--     Skip Master Reality auto-upgrade check
--
--   forceShuffleDeck = false (for modders)
--     When destination="DECK", do a full shuffle instead of insert
-- }
--
-- Returns: array of created card instances

local AcquireCard = {}

local Utils = require("utils")
local Cards = require("Data.cards")

-- Helper: Build card pool from all available cards
local function buildCardPool(world, filter)
    local pool = {}

    for _, card in pairs(Cards) do
        if type(card) == "table" and card.id then
            local include = true
            if filter then
                include = filter(world, card)
            end

            if include then
                table.insert(pool, card)
            end
        end
    end

    return pool
end

-- Helper: Get cards by state from combat deck
local function getCardsByState(deck, state)
    local cards = {}
    for _, card in ipairs(deck) do
        if card.state == state then
            table.insert(cards, card)
        end
    end
    return cards
end

-- Helper: Insert card into deck at position (NOT full shuffle)
local function insertIntoDrawPile(deck, card, position)
    local drawPile = getCardsByState(deck, "DECK")
    local drawPileSize = #drawPile

    -- Determine insert index
    local insertIndex
    if position == "random" or position == nil then
        -- Random position in [1, drawPileSize+1]
        insertIndex = math.random(1, drawPileSize + 1)
    elseif position == "top" then
        insertIndex = 1
    elseif position == "bottom" then
        insertIndex = drawPileSize + 1
    elseif type(position) == "number" then
        insertIndex = math.max(1, math.min(position, drawPileSize + 1))
    else
        insertIndex = math.random(1, drawPileSize + 1)
    end

    -- Find the actual deck index to insert at
    -- We need to find where in the full deck the Nth "DECK" card is
    local deckCardsFound = 0
    local actualInsertIndex = #deck + 1  -- Default to end

    for i, c in ipairs(deck) do
        if c.state == "DECK" then
            deckCardsFound = deckCardsFound + 1
            if deckCardsFound == insertIndex then
                actualInsertIndex = i
                break
            end
        end
    end

    -- If insertIndex is beyond current draw pile, insert at end
    if insertIndex > drawPileSize then
        actualInsertIndex = #deck + 1
    end

    table.insert(deck, actualInsertIndex, card)
end

-- Main execution function
function AcquireCard.execute(world, player, cardSource, options)
    options = options or {}

    -- Default values
    local destination = options.destination or "HAND"
    local position = options.position or "random"
    local tags = options.tags or {}
    local count = options.count or 1
    local skipMasterReality = options.skipMasterReality or false
    local forceShuffleDeck = options.forceShuffleDeck or false

    -- Determine target deck
    local inCombat = player.combatDeck ~= nil
    local targetDeck = options.targetDeck
    if not targetDeck then
        targetDeck = inCombat and "combat" or "master"
    end

    -- Select card template(s) to acquire
    local cardTemplates = {}

    if type(cardSource) == "table" and cardSource.filter then
        -- Filter-based selection
        local pool = buildCardPool(world, cardSource.filter)
        local selectCount = cardSource.count or 1

        if #pool == 0 then
            table.insert(world.log, "AcquireCard: No cards match filter")
            return {}
        end

        -- Select N unique cards from pool
        local selectedCount = math.min(selectCount, #pool)
        for i = 1, selectedCount do
            local index = math.random(1, #pool)
            table.insert(cardTemplates, pool[index])
            table.remove(pool, index)  -- Remove to avoid duplicates
        end
    else
        -- Direct template provided
        table.insert(cardTemplates, cardSource)
    end

    -- Create copies of selected template(s)
    local createdCards = {}

    for _, template in ipairs(cardTemplates) do
        for i = 1, count do
            -- Deep copy the card template
            local newCard = Utils.deepCopyCard and Utils.deepCopyCard(template) or Utils.copyCardTemplate(template)

            -- Check for Master Reality power: auto-upgrade created cards
            if not skipMasterReality and Utils.hasPower(player, "MasterReality") then
                if not newCard.upgraded and type(newCard.onUpgrade) == "function" then
                    newCard:onUpgrade()
                    newCard.upgraded = true
                end
            end

            -- Apply tags
            for _, tag in ipairs(tags) do
                newCard[tag] = 1
            end

            -- Handle destination
            if targetDeck == "combat" and inCombat then
                -- Add to combat deck
                if destination == "DECK" then
                    -- Insert into draw pile at position
                    newCard.state = "DECK"
                    insertIntoDrawPile(player.combatDeck, newCard, position)

                    -- Optional: full shuffle (for modders)
                    if forceShuffleDeck then
                        Utils.shuffleDeck(player.combatDeck, world)
                    end

                    table.insert(world.log, "Inserted " .. newCard.name .. " into draw pile")
                elseif destination == "HAND" then
                    newCard.state = "HAND"
                    table.insert(player.combatDeck, newCard)

                    local tagInfo = ""
                    if newCard.costsZeroThisTurn == 1 then
                        tagInfo = " (costs 0 this turn)"
                    elseif newCard.costsZeroThisCombat == 1 then
                        tagInfo = " (costs 0 this combat)"
                    end
                    table.insert(world.log, "Added " .. newCard.name .. " to hand" .. tagInfo)
                elseif destination == "DISCARD_PILE" then
                    newCard.state = "DISCARD_PILE"
                    table.insert(player.combatDeck, newCard)
                    table.insert(world.log, "Added " .. newCard.name .. " to discard pile")
                else
                    -- Custom state (e.g., "DRAFT", "NIGHTMARE")
                    newCard.state = destination
                    table.insert(player.combatDeck, newCard)
                    table.insert(world.log, "Added " .. newCard.name .. " (state: " .. destination .. ")")
                end
            else
                -- Add to master deck (permanent)
                table.insert(player.masterDeck, newCard)

                if world.log then
                    table.insert(world.log, "Added " .. newCard.name .. " to deck")
                end
            end

            table.insert(createdCards, newCard)
        end
    end

    return createdCards
end

return AcquireCard
