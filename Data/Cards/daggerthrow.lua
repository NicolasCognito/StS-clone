return {
    DaggerThrow = {
        id = "DaggerThrow",
        name = "Dagger Throw",
        cost = 1,
        type = "ATTACK",
        damage = 9,
        bonusDamage = 4,  -- Bonus damage if card is discarded
        contextProvider = "enemy",
        description = "Deal 9 damage. Discard 1: Deal 4 damage.",

        onPlay = function(self, world, player, target)
            -- Deal initial damage
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = target,
                card = self
            })
        end,

        -- POST-PLAY PHASE: Prompt to discard a card from hand
        postPlayContext = {
            source = "combat",
            count = {min = 0, max = 1},  -- Optional: can choose 0 or 1 card
            filter = function(world, player, card, candidateCard)
                -- Can only discard cards from hand (not the card being played)
                return candidateCard.state == "HAND"
            end
        },

        postPlayEffect = function(self, world, player, discardedCards, originalTarget)
            if #discardedCards > 0 then
                local discardedCard = discardedCards[1]

                -- Move card to discard pile
                discardedCard.state = "DISCARD_PILE"
                table.insert(world.log, player.id .. " discarded " .. discardedCard.name)

                -- Deal bonus damage to the original target
                world.queue:push({
                    type = "ON_DAMAGE",
                    attacker = player,
                    defender = originalTarget,
                    card = self,
                    damageOverride = self.bonusDamage  -- Use bonus damage instead of main damage
                })
            else
                table.insert(world.log, player.id .. " chose not to discard")
            end
        end,

        onUpgrade = function(self)
            self.damage = 12
            self.bonusDamage = 6
            self.description = "Deal 12 damage. Discard 1: Deal 6 damage."
        end
    }
}
