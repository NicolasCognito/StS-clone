return {
    Mayhem = {
        id = "Mayhem",
        name = "Mayhem",
        cost = 2,
        type = "POWER",
        character = "COLORLESS",
        rarity = "RARE",
        description = "At the start of your turn, play the top card of your draw pile.",

        onPlay = function(self, world, player, target)
            -- Apply Mayhem status effect
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "mayhem",
                amount = 1
            })
        end,

        onUpgrade = function(self)
            self.cost = 1
            self.description = "At the start of your turn, play the top card of your draw pile."
        end
    }
}
