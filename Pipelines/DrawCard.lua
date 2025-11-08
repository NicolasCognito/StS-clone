-- DRAW CARD PIPELINE
-- world: the complete game state
-- player: the player character
-- count: number of cards to draw
--
-- Handles:
-- - Draw from deck (change card.state from DECK to HAND)
-- - Shuffle discard back into deck if deck is empty
-- - Apply Confused status (randomize cost 0-3)
-- - Combat logging
--
-- Uses card state system: all cards are in player.cards[] with state property

local DrawCard = {}

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

function DrawCard.execute(world, player, count)
    for i = 1, count do
        local deckCards = getCardsByState(player, "DECK")

        -- If deck is empty, shuffle discard back into deck
        if #deckCards == 0 then
            local discardCards = getCardsByState(player, "DISCARD_PILE")
            if #discardCards == 0 then
                -- No cards to draw
                break
            end
            -- Shuffle discard into deck (change state)
            for _, card in ipairs(discardCards) do
                card.state = "DECK"
            end
            table.insert(world.log, "Deck reshuffled")
            deckCards = getCardsByState(player, "DECK")
        end

        -- Draw from deck (change first card's state from DECK to HAND)
        if #deckCards > 0 then
            local card = deckCards[1]
            card.state = "HAND"

            -- Apply Confused status: randomize cost when drawing
            if player.status and player.status.confused and player.status.confused > 0 then
                card.confused = math.random(0, 3)
            end
        end
    end

    table.insert(world.log, player.id .. " drew " .. count .. " cards")
end

return DrawCard
