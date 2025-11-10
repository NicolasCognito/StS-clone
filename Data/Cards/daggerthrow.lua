return {
    DaggerThrow = {
        id = "DaggerThrow",
        name = "Dagger Throw",
        cost = 1,
        type = "ATTACK",
        damage = 9,
        description = "Deal 9 damage. Draw 1 card. Discard 1 card.",

        onPlay = function(self, world, player)
            -- Request enemy context
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Push damage event
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })

            -- Push draw event
            world.queue:push({
                type = "ON_DRAW",
                player = player,
                count = 1
            })

            -- Request card discard context
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "cards",
                    stability = "temp",
                    source = "combat",
                    count = {min = 1, max = 1},
                    filter = function(world, player, card, candidateCard)
                        return candidateCard.state == "HAND"
                    end
                }
            })

            -- Push discard event with lazy-evaluated card
            world.queue:push({
                type = "ON_DISCARD",
                card = function() return world.combat.tempContext[1] end,
                player = player
            })
        end,

        onUpgrade = function(self)
            self.damage = 12
            self.description = "Deal 12 damage. Draw 1 card. Discard 1 card."
        end
    }
}
