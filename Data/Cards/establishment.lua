return {
    Establishment = {
        id = "Establishment",
        name = "Establishment",
        cost = 1,
        type = "POWER",
        character = "WATCHER",
        rarity = "RARE",
        description = "Whenever a card is Retained, reduce its cost by 1 this combat.",
        innate = false,

        onPlay = function(self, world, player)
            -- Apply Establishment status effect
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "establishment",
                amount = 1
            })
        end,

        onUpgrade = function(self)
            self.innate = true
            self.description = "Innate. Whenever a card is Retained, reduce its cost by 1 this combat."
            self.upgraded = true
        end
    }
}
