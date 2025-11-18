-- Void (Status)
-- Unplayable. Whenever this card is drawn, lose 1 Energy. Ethereal.
-- Status card added by certain enemies (Awakened One's Sludge attack)

local Utils = require("utils")

return {
    Void = {
        id = "Void",
        name = "Void",
        cost = -2,  -- Unplayable
        type = "STATUS",
        character = "COLORLESS",
        rarity = "COMMON",
        unplayable = true,
        ethereal = true,
        description = "Unplayable. Whenever this card is drawn, lose 1 Energy. Ethereal.",

        -- Hook triggered when card is drawn (handled by DrawCard pipeline)
        onDraw = function(self, world, player)
            Utils.LoseEnergy(world, player, 1)
        end,

        -- No onPlay function - this card cannot be played
        -- Ethereal means it's removed at end of turn if in hand (handled by EndTurn pipeline)
    }
}
