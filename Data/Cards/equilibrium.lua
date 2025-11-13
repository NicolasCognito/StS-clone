return {
    Equilibrium = {
        id = "Equilibrium",
        name = "Equilibrium",
        cost = 2,
        type = "SKILL",
        character = "DEFECT",
        rarity = "UNCOMMON",
        description = "Gain 13 Block. Retain your hand this turn.",
        block = 13,

        onPlay = function(self, world, player)
            -- Gain block
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                amount = self.block
            })

            -- Retain entire hand this turn (except self and ethereal cards)
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    for _, card in ipairs(player.combatDeck) do
                        -- Retain all cards in hand except self and ethereal cards
                        if card.state == "HAND" and card ~= self and not card.ethereal then
                            card.retainThisTurn = true
                        end
                    end
                    table.insert(world.log, "Hand will be retained this turn")
                end
            })
        end,

        onUpgrade = function(self)
            self.block = 16
            self.description = "Gain 16 Block. Retain your hand this turn."
            self.upgraded = true
        end
    }
}
