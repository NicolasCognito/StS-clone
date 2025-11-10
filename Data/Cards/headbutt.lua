local Utils = require("utils")

return {
    Headbutt = {
        id = "Headbutt",
        name = "Headbutt",
        cost = 1,
        type = "ATTACK",
        damage = 9,
        contextProvider = "enemy",
        description = "Deal 9 damage. Put a card from your discard pile on top of your draw pile.",

        onPlay = function(self, world, player, target)
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = target,
                card = self
            })
        end,

        postPlayContext = {
            source = "combat",
            count = {min = 1, max = 1},
            filter = function(world, player, card, candidateCard)
                return candidateCard.state == "DISCARD_PILE"
            end
        },

        postPlayEffect = function(self, world, player, selectedCards)
            local retrievedCard = selectedCards and selectedCards[1]
            if not retrievedCard then
                table.insert(world.log, "Headbutt could not find a card to place on top of the draw pile.")
                return
            end

            retrievedCard.state = "DECK"
            if not Utils.moveCardToDeckTop(player.combatDeck, retrievedCard) then
                table.insert(world.log, "Headbutt failed to move " .. retrievedCard.name .. " onto the draw pile.")
                return
            end

            table.insert(world.log, player.name .. " placed " .. retrievedCard.name .. " on top of the draw pile.")
        end,

        onUpgrade = function(self)
            self.damage = 12
            self.description = "Deal 12 damage. Put a card from your discard pile on top of your draw pile."
        end
    }
}
