local Utils = require("utils")

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
            -- Add a random Attack using new filter-based AcquireCard
            world.queue:push({
                type = "ON_ACQUIRE_CARD",
                player = player,
                cardSource = {
                    filter = function(w, card)
                        return card.type == "ATTACK" and Utils.matchesPlayerPool(card, player, true)
                    end,
                    count = 1
                },
                options = {
                    destination = "HAND",
                    tags = {"costsZeroThisTurn"}
                }
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Add a random Attack to your hand. It costs 0 this turn."
        end
    }
}
