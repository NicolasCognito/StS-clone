return {
    Corruption = {
        id = "Corruption",
        name = "Corruption",
        cost = 3,
        type = "POWER",
        description = "Skills cost 0. Whenever you play a Skill, Exhaust it.",

        onPlay = function(self, world, player, target)
            -- Apply Corruption power
            local Powers = require("Data.powers")
            world.queue:push({
                type = "ON_APPLY_POWER",
                target = player,
                powerTemplate = Powers.Corruption
            })
        end,

        onUpgrade = function(self)
            self.cost = 2
            self.description = "Skills cost 0. Whenever you play a Skill, Exhaust it."
        end
    }
}
