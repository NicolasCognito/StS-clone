local ContextValidators = require("Utils.ContextValidators")

return {
    Sanctity = {
        id = "Sanctity",
        name = "Sanctity",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "UNCOMMON",
        block = 6,
        description = "Gain 6 Block. If the previous card played was a Skill, draw 2 cards.",
        stableContextValidator = ContextValidators.anyEnemyAlive,

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                amount = self.block,
                card = self
            })

            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local combat = world.combat
                    if not combat or not combat.cardsPlayedThisTurn then
                        return
                    end

                    local count = #combat.cardsPlayedThisTurn
                    if count == 0 then
                        return
                    end

                    local lastCard = combat.cardsPlayedThisTurn[count]
                    if lastCard.type == "SKILL" then
                        world.queue:push({type = "ON_DRAW", player = player, count = 2})
                        table.insert(world.log, "Sanctity draws 2 cards for following a Skill")
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.block = 9
            self.description = "Gain 9 Block. If the previous card played was a Skill, draw 2 cards."
        end
    }
}
