return {
    Corruption = {
        id = "Corruption",
        name = "Corruption",
        cost = 3,
        type = "POWER",
        character = "IRONCLAD",
        rarity = "RARE",
        description = "Skills cost 0. Whenever you play a Skill, Exhaust it.",

        onPlay = function(self, world, player, target)
            -- Apply Corruption status effect
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "corruption",
                amount = 1
            })
        end,

        onUpgrade = function(self)
            self.cost = 2
            self.description = "Skills cost 0. Whenever you play a Skill, Exhaust it."
        end
    }
}
