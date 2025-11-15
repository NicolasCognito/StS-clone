-- Necronomicurse (Curse)
-- Unplayable. There is no escape from this Curse.
-- When exhausted, immediately returns to hand (or discard pile if hand is full).
-- Cannot be played even with Blue Candle (unlike other curses).

return {
    Necronomicurse = {
        id = "Necronomicurse",
        name = "Necronomicurse",
        cost = 0,
        type = "CURSE",
        character = "CURSE",
        rarity = "CURSE",
        description = "Unplayable. There is no escape from this Curse.",

        -- Completely unplayable, even with Blue Candle
        isPlayable = function(self, world, player)
            return false, "Necronomicurse cannot be played"
        end,

        -- Hook into Exhaust pipeline
        -- This runs AFTER the card has been moved to EXHAUSTED_PILE
        -- by Exhaust.lua (lines 41-45), and AFTER Strange Spoon check
        onExhaust = function(self, world, player)
            -- Queue a custom effect to return this card to hand/discard
            -- We use ON_CUSTOM_EFFECT to ensure proper timing and logging
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local Utils = require("utils")

                    -- Find this specific card instance in the exhausted pile
                    local found = false
                    for i, card in ipairs(player.combatDeck) do
                        if card == self and card.state == "EXHAUSTED_PILE" then
                            found = true

                            -- Check hand size (default max is 10)
                            local maxHandSize = 10
                            local handCards = Utils.getCardsByState(player.combatDeck, "HAND")
                            local currentHandSize = #handCards

                            if currentHandSize < maxHandSize then
                                -- Room in hand: return to hand
                                card.state = "HAND"
                                table.insert(world.log, "Necronomicurse returns to your hand!")
                            else
                                -- Hand is full: send to discard pile
                                card.state = "DISCARD_PILE"
                                table.insert(world.log, "Necronomicurse returns to your discard pile! (hand full)")
                            end

                            break
                        end
                    end

                    -- Safety check (should always find the card)
                    if not found then
                        table.insert(world.log, "[WARNING] Necronomicurse not found in exhausted pile")
                    end
                end
            })
        end
    }
}
