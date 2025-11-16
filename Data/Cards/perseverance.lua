return {
    Perseverance = {
        id = "Perseverance",
        name = "Perseverance",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "Gain 5 Block. Retain. When Retained, increase this card's Block by 2 this combat.",
        retain = true,
        block = 5,
        blockGainOnRetain = 2,

        onPlay = function(self, world, player)
            -- Gain block
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                amount = self.block,
                source = self
            })
        end,

        -- Called when card is retained at end of turn
        onRetained = function(self, world, player)
            -- Increase block permanently for this combat
            local blockGain = self.blockGainOnRetain or 0
            self.block = self.block + blockGain

            table.insert(world.log, self.name .. " Block increased to " .. self.block .. " (+" .. blockGain .. ")")
        end,

        onUpgrade = function(self)
            self.block = 7
            self.blockGainOnRetain = 3
            self.description = "Gain 7 Block. Retain. When Retained, increase this card's Block by 3 this combat."
            self.upgraded = true
        end
    }
}
