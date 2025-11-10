local Utils = require("utils")

return {
    Headbutt = {
        id = "Headbutt",
        name = "Headbutt",
        cost = 1,
        type = "ATTACK",
        damage = 9,
        contextProvider = {type = "enemy", stability = "stable"},
        description = "Deal 9 damage. Put a card from your discard pile on top of your draw pile.",

        onPlay = function(self, world, player)
            if not self.additionalContextCollected then
                -- PHASE 1: Main effect (damage)
                local target = world.combat.latestContext  -- enemy from main contextProvider

                world.queue:push({
                    type = "ON_DAMAGE",
                    attacker = player,
                    defender = target,
                    card = self
                })

                -- Request additional context for card retrieval
                world.combat.contextRequest = {
                    card = self,
                    contextProvider = {
                        type = "cards",
                        stability = "temp",
                        source = "combat",
                        count = {min = 1, max = 1},
                        filter = function(world, player, card, candidateCard)
                            return candidateCard.state == "DISCARD_PILE"
                        end
                    }
                }
                self.additionalContextCollected = true
            else
                -- PHASE 2: Additional effect (retrieve card to deck top)
                local selectedCards = world.combat.latestContext
                local retrievedCard = selectedCards and selectedCards[1]

                if not retrievedCard then
                    table.insert(world.log, "Headbutt could not find a card to place on top of the draw pile.")
                else
                    retrievedCard.state = "DECK"
                    if not Utils.moveCardToDeckTop(player.combatDeck, retrievedCard) then
                        table.insert(world.log, "Headbutt failed to move " .. retrievedCard.name .. " onto the draw pile.")
                    else
                        table.insert(world.log, player.name .. " placed " .. retrievedCard.name .. " on top of the draw pile.")
                    end
                end

                self.additionalContextCollected = nil  -- Reset for next play
            end
        end,

        onUpgrade = function(self)
            self.damage = 12
            self.description = "Deal 12 damage. Put a card from your discard pile on top of your draw pile."
        end
    }
}
