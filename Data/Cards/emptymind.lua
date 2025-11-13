return {
    EmptyMind = {
        id = "EmptyMind",
        name = "Empty Mind",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "Exit your stance. Draw 2 cards.",
        drawAmount = 2,

        onPlay = function(self, world, player)
            -- Exit stance (set to nil for neutral)
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = nil
            })

            -- Draw cards
            for i = 1, self.drawAmount do
                world.queue:push({type = "ON_DRAW"})
            end
        end,

        onUpgrade = function(self)
            self.drawAmount = 3
            self.description = "Exit your stance. Draw 3 cards."
            self.upgraded = true
        end
    }
}
