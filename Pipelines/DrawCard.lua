-- DRAW CARD PIPELINE
-- world: the complete game state
-- player: the player character
-- count: number of cards to draw
--
-- Handles:
-- - Draw from deck
-- - Shuffle discard back into deck if deck is empty
-- - Add cards to hand
-- - Combat logging

local DrawCard = {}

function DrawCard.execute(world, player, count)
    for i = 1, count do
        -- If deck is empty, shuffle discard back into deck
        if #player.deck == 0 then
            if #player.discard == 0 then
                -- No cards to draw
                break
            end
            -- Shuffle discard into deck
            for _, card in ipairs(player.discard) do
                table.insert(player.deck, card)
            end
            player.discard = {}
            table.insert(world.log, "Deck reshuffled")
        end

        -- Draw from deck
        if #player.deck > 0 then
            local card = table.remove(player.deck)
            table.insert(player.hand, card)
        end
    end

    table.insert(world.log, player.id .. " drew " .. count .. " cards")
end

return DrawCard
