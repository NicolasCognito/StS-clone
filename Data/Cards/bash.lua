return {
    Bash = {
        id = "Bash",
        name = "Bash",
        cost = 1,
        type = "ATTACK",
        damage = 8,
        contextProvider = {type = "enemy", stability = "stable"},
        description = "Deal 8 damage. Apply 2 Vulnerable.",

        onPlay = function(self, world, player)
            local target = world.combat.latestContext
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = target,
                card = self
            })
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = target,
                effectType = "Vulnerable",
                amount = 2,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.damage = 10
            self.description = "Deal 10 damage. Apply 2 Vulnerable."
        end
    }
}
