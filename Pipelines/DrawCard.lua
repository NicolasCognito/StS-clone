-- DRAW CARD PIPELINE
-- world: the complete game state
-- player: the player character
-- count: number of cards to draw
--
-- Handles:
-- - Check cannotDraw flag (Bullet Time effect)
-- - Draw from deck (change card.state from DECK to HAND)
-- - Shuffle discard back into deck if deck is empty
-- - Apply Confused status (randomize cost 0-3)
-- - Combat logging
--
-- Uses card state system: all cards are in player.combatDeck[] with state property

local DrawCard = {}

local Utils = require("utils")

function DrawCard.execute(world, player, count)
    -- Check if player cannot draw (Bullet Time effect)
    if player.cannotDraw then
        table.insert(world.log, "Cannot draw cards this turn")
        return
    end

    player.status = player.status or {}
    local playerName = player.name or player.id or "Player"

    if player.status.no_draw and player.status.no_draw > 0 then
        table.insert(world.log, playerName .. " is unable to draw due to No Draw")
        return
    end

    for i = 1, count do
        local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")

        -- If deck is empty, shuffle discard back into deck
        if #deckCards == 0 then
            local discardCards = Utils.getCardsByState(player.combatDeck, "DISCARD_PILE")
            if #discardCards == 0 then
                -- No cards to draw
                break
            end
            -- Shuffle discard into deck (change state)
            for _, card in ipairs(discardCards) do
                card.state = "DECK"
            end
            -- Shuffle the deck for random card order
            Utils.shuffleDeck(player.combatDeck)
            table.insert(world.log, "Deck reshuffled")
            deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
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
