return {
    HeavyBlade = {
        id = "Heavy_Blade",
        name = "Heavy Blade",
        cost = 2,
        type = "ATTACK",
        damage = 14,
        strengthMultiplier = 3,
        contextProvider = "enemy",
        description = "Deal 14 damage. Strength affects this card 3 times.",

        onPlay = function(self, world, player, target)
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = target,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.strengthMultiplier = 5
            self.description = "Deal 14 damage. Strength affects this card 5 times."
        end
    }
}
