return {
    InfernalBlade = {
        id = "Infernal_Blade",
        name = "Infernal Blade",
        cost = 1,
        type = "SKILL",
        character = "IRONCLAD",
        rarity = "UNCOMMON",
        description = "Add a random Attack to your hand. It costs 0 this turn.",

        onPlay = function(self, world, player, target)
            -- Use AcquireCard pipeline with costsZeroThisTurn tag
            local Cards = require("Data.cards")
            world.queue:push({
                type = "ON_ACQUIRE_CARD",
                player = player,
                cardTemplate = Cards.Strike,  -- For testing, just add Strike (would be random in real version)
                tags = {"costsZeroThisTurn"}
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Add a random Attack to your hand. It costs 0 this turn."
        end
    }
}
