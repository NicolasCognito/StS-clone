return {
    Tranquility = {
        id = "Tranquility",
        name = "Tranquility",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "Enter Calm. Retain. Exhaust.",
        retain = true,
        exhausts = true,

        onPlay = function(self, world, player)
            -- Enter Calm stance
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = "Calm"
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Enter Calm. Retain. Exhaust."
            self.upgraded = true
        end
    }
}
