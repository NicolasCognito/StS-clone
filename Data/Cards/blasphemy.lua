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

            -- Set die_next_turn status (will decrement at end of each turn)
            -- Set to 2: decrements to 1 at end of this turn, then 0 at end of next turn (death)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "die_next_turn",
                amount = 2
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Enter Divinity. Die next turn. Retain."
            self.upgraded = true
        end
    }
}
