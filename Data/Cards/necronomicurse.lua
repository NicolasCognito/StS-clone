-- Necronomicurse (Curse)
-- Unplayable. No escape.
-- Can be played with Blue Candle relic (handled elsewhere)

local Utils = require("utils")

return {
    Necronomicurse = {
        id = "Necronomicurse",
        name = "Necronomicurse",
        cost = 0,
        type = "CURSE",
        character = "CURSE",
        rarity = "CURSE",
        exhausts = true,
        description = "Unplayable. There is no escape from this curse.",

        isPlayable = function(self, world, player)
            return false, "Necronomicurse is unplayable"
        end,

        onExhaust = function(self, world, player)
            local maxHandSize = player.maxHandSize or 10
            local handSize = Utils.getCardCountByState(player.combatDeck, "HAND")

            if handSize < maxHandSize then
                self.state = "HAND"
                table.insert(world.log, "Necronomicurse refuses to leave and returns to hand")
            else
                self.state = "DISCARD_PILE"
                table.insert(world.log, "Necronomicurse couldn't return (hand full) and falls into the discard pile")
            end
        end
    }
}
