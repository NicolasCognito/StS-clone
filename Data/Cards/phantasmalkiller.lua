return {
    PhantasmalKiller = {
        id = "Phantasmal_Killer",
        name = "Phantasmal Killer",
        cost = 1,
        type = "SKILL",
        character = "SILENT",
        rarity = "RARE",
        description = "Your next turn, Attacks deal double damage.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "phantasmal",
                amount = 1,
                source = self.name
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.upgraded = true
            self.description = "Your next turn, Attacks deal double damage."
        end
    }
}
