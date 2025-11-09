return {
    DaggerThrow = {
        id = "DaggerThrow",
        name = "Dagger Throw",
        cost = 1,
        type = "ATTACK",
        damage = 9,
        contextProvider = "enemy",
        description = "Deal 9 damage. Draw 1 card. Discard 1 card.",

        onPlay = function(self, world, player, target)
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
        end,

        -- POST-PLAY PHASE: Prompt to discard a card from hand
        postPlayContext = {
            source = "combat",
            count = {min = 1, max = 1},  -- Must discard exactly 1 card
            filter = function(world, player, card, candidateCard)
                -- Can only discard cards from hand
                return candidateCard.state == "HAND"
            end
        },

        postPlayEffect = function(self, world, player, discardedCards, originalTarget)
            local discardedCard = discardedCards[1]

            -- Move card to discard pile
            discardedCard.state = "DISCARD_PILE"
            table.insert(world.log, player.id .. " discarded " .. discardedCard.name)
        end,

        onUpgrade = function(self)
            self.damage = 12
            self.description = "Deal 12 damage. Draw 1 card. Discard 1 card."
        end
    }
}
