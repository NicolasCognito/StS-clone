return {
    Halt = {
        id = "Halt",
        name = "Halt",
        cost = 0,
        type = "SKILL",
        character = "WATCHER",
        rarity = "COMMON",
        description = "Gain 3 Block. If you are in Wrath, gain 9 additional Block.",
        baseBlock = 3,
        wrathBonusBlock = 9,

        onPlay = function(self, world, player)
            local blockAmount = self.baseBlock

            -- Check if in Wrath stance
            if player.currentStance == "Wrath" then
                blockAmount = blockAmount + self.wrathBonusBlock
            end

            -- Gain block
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                amount = blockAmount,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.baseBlock = 4
            self.wrathBonusBlock = 12
            self.description = "Gain 4 Block. If you are in Wrath, gain 12 additional Block."
            self.upgraded = true
        end
    }
}
