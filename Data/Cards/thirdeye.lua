return {
    ThirdEye = {
        id = "ThirdEye",
        name = "Third Eye",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "COMMON",
        block = 7,
        scryAmount = 3,
        description = "Gain 7 Block. Scry 3.",

        onPlay = function(self, world, player)
            -- Gain block
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                amount = self.block
            })

            -- Request scry context (show top 3 cards)
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "cards",
                    stability = "temp",
                    scry = self.scryAmount,
                    count = {min = 0, max = self.scryAmount}
                }
            })

            -- Process scry (move selected cards to discard)
            world.queue:push({
                type = "ON_SCRY"
            })
        end,

        onUpgrade = function(self)
            self.block = 9
            self.scryAmount = 5
            self.description = "Gain 9 Block. Scry 5."
        end
    }
}
