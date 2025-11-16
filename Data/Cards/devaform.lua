return {
    DevaForm = {
        id = "DevaForm",
        name = "Deva Form",
        cost = 3,
        type = "POWER",
        character = "WATCHER",
        rarity = "RARE",
        ethereal = true,
        initialEnergyGain = 1,
        description = "Ethereal. At the start of your turn, gain 1 Energy and increase this gain by 1.",

        onPlay = function(self, world, player)
            -- Apply Deva Form statuses: current energy gain and the growth per turn
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "deva",
                amount = self.initialEnergyGain,
                source = self
            })

            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "deva_growth",
                amount = 1,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.cost = 2
            self.initialEnergyGain = 2
            self.description = "Ethereal. At the start of your turn, gain 2 Energy and increase this gain by 1."
        end
    }
}

