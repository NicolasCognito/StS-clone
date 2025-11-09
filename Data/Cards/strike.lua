return {
    Strike = {
        id = "Strike",
        name = "Strike",
        cost = 1,
        type = "ATTACK",
        damage = 6,
        Targeted = 1,
        description = "Deal 6 damage.",

        onPlay = function(self, world, player, target)
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = target,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.damage = 8
            self.description = "Deal 8 damage."
        end
    }
}
