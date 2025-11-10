return {
    Strike = {
        id = "Strike",
        name = "Strike",
        cost = 1,
        type = "ATTACK",
        character = "IRONCLAD",
        rarity = "STARTER",
        damage = 6,
        description = "Deal 6 damage.",

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
        end,

        onUpgrade = function(self)
            self.damage = 8
            self.description = "Deal 8 damage."
        end
    }
}
