return {
    Skewer = {
        id = "Skewer",
        name = "Skewer",
        cost = "X",
        type = "ATTACK",
        damage = 7,
        contextProvider = "enemy",
        description = "Deal 7 damage X times.",

        onPlay = function(self, world, player, target)
            -- Deal damage X times to the same target (where X = energySpent)
            for i = 1, self.energySpent do
                world.queue:push({
                    type = "ON_DAMAGE",
                    attacker = player,
                    defender = target,
                    card = self
                })
            end
        end,

        onUpgrade = function(self)
            self.damage = 10
            self.description = "Deal 10 damage X times."
        end
    }
}
