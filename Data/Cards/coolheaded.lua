return {
    Coolheaded = {
        id = "Coolheaded",
        name = "Coolheaded",
        cost = 1,
        type = "SKILL",
        character = "DEFECT",
        rarity = "COMMON",
        cardsToDraw = 1,
        description = "Channel 1 Frost. Draw 1 card.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_CHANNEL_ORB",
                orbType = "Frost"
            })
            world.queue:push({
                type = "ON_DRAW",
                player = player,
                count = self.cardsToDraw
            })
        end,

        onUpgrade = function(self)
            self.cardsToDraw = 2
            self.description = "Channel 1 Frost. Draw 2 cards."
        end
    }
}
