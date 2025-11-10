return {
    DaggerThrow = {
        id = "DaggerThrow",
        name = "Dagger Throw",
        cost = 1,
        type = "ATTACK",
        damage = 9,
        contextProvider = {type = "enemy", stability = "stable"},
        description = "Deal 9 damage. Draw 1 card. Discard 1 card.",

        onPlay = function(self, world, player)
            if not self.additionalContextCollected then
                -- PHASE 1: Main effect (damage + draw)
                local target = world.combat.latestContext  -- enemy from main contextProvider

                -- Deal damage
                world.queue:push({
                    type = "ON_DAMAGE",
                    attacker = player,
                    defender = target,
                    card = self
                })

                -- Draw 1 card
                world.queue:push({
                    type = "ON_DRAW",
                    player = player,
                    count = 1
                })

                -- Request additional context for discard
                world.combat.contextRequest = {
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
                }
                self.additionalContextCollected = true
            else
                -- PHASE 2: Additional effect (discard)
                local cardsToDiscard = world.combat.latestContext
                if cardsToDiscard and #cardsToDiscard > 0 then
                    world.queue:push({
                        type = "ON_DISCARD",
                        card = cardsToDiscard[1],
                        player = player
                    })
                end
                self.additionalContextCollected = nil  -- Reset for next play
            end
        end,

        onUpgrade = function(self)
            self.damage = 12
            self.description = "Deal 12 damage. Draw 1 card. Discard 1 card."
        end
    }
}
