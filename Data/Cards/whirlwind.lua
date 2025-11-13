return {
    Whirlwind = {
        id = "Whirlwind",
        name = "Whirlwind",
        cost = "X",
        type = "ATTACK",
        character = "IRONCLAD",
        rarity = "UNCOMMON",
        damage = 5,
        description = "Deal 5 damage to ALL enemies X times.",

        onPlay = function(self, world, player)
            -- Deal damage X times (where X = energySpent)
            for i = 1, self.energySpent do
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = player,
                    defender = "all",  -- AOE wrapper
                    card = self
                })
            end
        end,

        onUpgrade = function(self)
            self.damage = 8
            self.description = "Deal 8 damage to ALL enemies X times."
        end
    }
}
