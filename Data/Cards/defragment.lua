return {
    Defragment = {
        id = "Defragment",
        name = "Defragment",
        cost = 1,
        type = "POWER",
        character = "DEFECT",
        rarity = "UNCOMMON",
        focusGain = 1,
        description = "Gain 1 Focus.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "Focus",
                amount = self.focusGain,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.focusGain = 2
            self.description = "Gain 2 Focus."
        end
    }
}
