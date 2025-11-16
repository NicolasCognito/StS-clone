-- NOTE: After Image's block trigger is implemented in Pipelines/AfterCardPlayed.lua

return {
    AfterImage = {
        id = "AfterImage",
        name = "After Image",
        cost = 1,
        type = "POWER",
        character = "SILENT",
        rarity = "RARE",
        blockPerCard = 1,
        innate = false,
        description = "Whenever you play a card, gain 1 Block.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "after_image",
                amount = self.blockPerCard,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.innate = true
            self.description = "Innate. Whenever you play a card, gain 1 Block."
        end
    }
}
