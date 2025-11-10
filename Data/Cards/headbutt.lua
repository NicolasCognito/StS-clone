local Utils = require("utils")

return {
    Headbutt = {
        id = "Headbutt",
        name = "Headbutt",
        cost = 1,
        type = "ATTACK",
        character = "IRONCLAD",
        rarity = "COMMON",
        damage = 9,
        description = "Deal 9 damage. Put a card from your discard pile on top of your draw pile.",

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

            -- Request card retrieval context
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "cards",
                    stability = "temp",
                    source = "combat",
                    count = {min = 1, max = 1},
                    filter = function(_, _, _, candidateCard)
                        return candidateCard.state == "DISCARD_PILE"
                    end
                }
            })

            -- Resolve selection once context has been collected
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local retrievedCard = world.combat.tempContext and world.combat.tempContext[1]
                    if not retrievedCard then
                        table.insert(world.log, "Headbutt could not find a card to place on top of the draw pile.")
                        return
                    end

                    retrievedCard.state = "DECK"
                    if not Utils.moveCardToDeckTop(player.combatDeck, retrievedCard) then
                        table.insert(world.log, "Headbutt failed to move " .. retrievedCard.name .. " onto the draw pile.")
                    else
                        table.insert(world.log, player.name .. " placed " .. retrievedCard.name .. " on top of the draw pile.")
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.damage = 12
            self.description = "Deal 12 damage. Put a card from your discard pile on top of your draw pile."
        end
    }
}
