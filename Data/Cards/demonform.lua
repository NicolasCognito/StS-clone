return {
    DemonForm = {
        id = "DemonForm",
        name = "Demon Form",
        cost = 3,
        type = "POWER",
        character = "IRONCLAD",
        rarity = "RARE",
        strengthPerTurn = 2,
        description = "At the start of your turn, gain 2 Strength.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "demon_form",
                amount = self.strengthPerTurn,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.strengthPerTurn = 3
            self.description = "At the start of your turn, gain 3 Strength."
        end
    }
}
