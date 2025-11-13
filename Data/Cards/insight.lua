return {
    Insight = {
        id = "Insight",
        name = "Insight",
        cost = 0,
        type = "SKILL",
        character = "WATCHER",
        rarity = "SPECIAL",
        description = "Retain. Draw 2 cards. Exhaust.",
        retain = true,
        exhausts = true,
        drawAmount = 2,

        onPlay = function(self, world, player)
            -- Draw cards
            for i = 1, self.drawAmount do
                world.queue:push({type = "ON_DRAW"})
            end
        end,

        onUpgrade = function(self)
            -- Insight doesn't upgrade in the base game
            self.upgraded = true
        end
    }
}
