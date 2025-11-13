local ContextValidators = require("Utils.ContextValidators")

return {
    Skewer = {
        id = "Skewer",
        name = "Skewer",
        cost = "X",
        type = "ATTACK",
        character = "IRONCLAD",
        rarity = "UNCOMMON",
        damage = 7,
        description = "Deal 7 damage X times.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            -- Request context collection
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Push events with lazy-evaluated fields
            -- Deal damage X times to the same target (where X = energySpent)
            for i = 1, self.energySpent do
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = player,
                    defender = function() return world.combat.stableContext end,
                    card = self
                })
            end
        end,

        onUpgrade = function(self)
            self.damage = 10
            self.description = "Deal 10 damage X times."
        end
    }
}
