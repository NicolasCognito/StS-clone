return {
    Blasphemy = {
        id = "Blasphemy",
        name = "Blasphemy",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "RARE",
        description = "Enter Divinity. Die next turn. Retain.",
        retain = true,

        onPlay = function(self, world, player)
            -- Enter Divinity stance immediately
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = "Divinity"
            })

            -- Set die_next_turn status (triggers at START of next turn)
            -- Non-degrading: set to 1, triggers next turn, then removed
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "die_next_turn",
                amount = 1
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Enter Divinity. Die next turn. Retain."
            self.upgraded = true
        end
    }
}
