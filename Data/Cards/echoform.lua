return {
    EchoForm = {
        id = "EchoForm",
        name = "Echo Form",
        cost = 3,
        type = "POWER",
        character = "DEFECT",
        rarity = "RARE",
        description = "Ethereal. The first card you play each turn is played twice.",
        ethereal = true,

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "echo_form",
                amount = 1,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.ethereal = false
            self.description = "The first card you play each turn is played twice."
        end
    }
}
