-- REFLEX
-- Silent Uncommon Skill
-- Unplayable. When discarded: Draw 2 (3) cards.

return {
    Reflex = {
        id = "Reflex",
        name = "Reflex",
        cost = 0,
        type = "SKILL",
        character = "SILENT",
        rarity = "UNCOMMON",
        upgraded = false,
        description = "Unplayable. When discarded: Draw 2 cards.",

        isPlayable = function(self, world, player)
            return false, "Reflex is unplayable"
        end,

        onDiscard = function(self, world, player)
            local DrawCard = require("Pipelines.DrawCard")
            local cardsToDraw = self.upgraded and 3 or 2
            table.insert(world.log, "Reflex triggers! Drawing " .. cardsToDraw .. " cards")
            DrawCard.execute(world, player, cardsToDraw)
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Unplayable. When discarded: Draw 3 cards."
        end
    }
}
