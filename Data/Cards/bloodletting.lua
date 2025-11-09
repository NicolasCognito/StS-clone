return {
    Bloodletting = {
        id = "Bloodletting",
        name = "Bloodletting",
        cost = 0,
        type = "SKILL",
        hpLoss = 3,
        energyGain = 2,
        description = "Lose 3 HP. Gain 2 Energy.",

        onPlay = function(self, world, player, target)
            -- Lose HP (ignores block - this is HP loss, not damage)
            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = nil,
                target = player,
                amount = self.hpLoss,
                tags = {"ignoreBlock"}  -- HP loss bypasses block
            })

            -- Gain energy directly (simple enough to not need a pipeline)
            player.energy = player.energy + self.energyGain
            table.insert(world.log, player.id .. " gained " .. self.energyGain .. " energy")
        end,

        onUpgrade = function(self)
            self.energyGain = 3
            self.description = "Lose 3 HP. Gain 3 Energy."
        end
    }
}
