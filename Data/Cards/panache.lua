return {
    Panache = {
        id = "Panache",
        name = "Panache",
        cost = 0,
        type = "POWER",
        character = "WATCHER",
        rarity = "RARE",
        description = "Every time you play 5 cards in a single turn, deal 10 damage to ALL enemies.",
        damage = 10,  -- Damage dealt on trigger

        onPlay = function(self, world, player)
            -- Apply Panache status effect
            -- Stacks represent the damage dealt
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "panache",
                amount = self.damage
            })
        end,

        onUpgrade = function(self)
            self.damage = 14
            self.description = "Every time you play 5 cards in a single turn, deal 14 damage to ALL enemies."
            self.upgraded = true
        end
    }
}
