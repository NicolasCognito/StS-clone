return {
    Crescendo = {
        id = "Crescendo",
        name = "Crescendo",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "COMMON",
        description = "Enter Wrath. Retain. Exhaust.",
        retain = true,
        exhausts = true,

        onPlay = function(self, world, player)
            -- Enter Wrath stance
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = "Wrath"
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Enter Wrath. Retain. Exhaust."
            self.upgraded = true
        end
    }
}
