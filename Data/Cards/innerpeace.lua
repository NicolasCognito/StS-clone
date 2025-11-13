return {
    InnerPeace = {
        id = "InnerPeace",
        name = "Inner Peace",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "If you are not in Calm, enter Calm. If you are in Calm, draw 2 cards.",
        drawAmount = 2,

        onPlay = function(self, world, player)
            if player.currentStance == "Calm" then
                -- Already in Calm: draw cards
                for i = 1, self.drawAmount do
                    world.queue:push({type = "ON_DRAW"})
                end
            else
                -- Not in Calm: enter Calm
                world.queue:push({
                    type = "CHANGE_STANCE",
                    newStance = "Calm"
                })
            end
        end,

        onUpgrade = function(self)
            self.drawAmount = 3
            self.description = "If you are not in Calm, enter Calm. If you are in Calm, draw 3 cards."
            self.upgraded = true
        end
    }
}
