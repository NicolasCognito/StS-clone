return {
    Bash = {
        id = "Bash",
        name = "Bash",
        cost = 1,
        type = "ATTACK",
        damage = 8,
        description = "Deal 8 damage. Apply 2 Vulnerable.",

        onPlay = function(self, world, player)
            -- Request context collection
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Push damage event with lazy-evaluated defender
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })

            -- Push status effect with lazy-evaluated target
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = function() return world.combat.stableContext end,
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
