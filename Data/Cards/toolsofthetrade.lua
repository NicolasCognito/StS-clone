return {
    ToolsOfTheTrade = {
        id = "ToolsOfTheTrade",
        name = "Tools of the Trade",
        cost = 1,
        type = "POWER",
        character = "SILENT",
        rarity = "RARE",
        description = "At the start of your turn, draw 1 card and discard 1 card.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "tools_of_the_trade",
                amount = 1
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "At the start of your turn, draw 1 card and discard 1 card."
        end
    }
}
