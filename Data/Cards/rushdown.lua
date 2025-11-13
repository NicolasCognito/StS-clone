return {
    Rushdown = {
        id = "Rushdown",
        name = "Rushdown",
        cost = 1,
        type = "POWER",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "Whenever you enter Wrath, draw 2 cards.",
        stacks = 1,

        onPlay = function(self, world, player)
            -- Apply Rushdown status effect
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "rushdown",
                amount = self.stacks
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Whenever you enter Wrath, draw 2 cards."
            self.upgraded = true
        end
    }
}
