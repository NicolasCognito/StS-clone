local ContextValidators = require("Utils.ContextValidators")

return {
    HeavyBlade = {
        id = "Heavy_Blade",
        name = "Heavy Blade",
        cost = 2,
        type = "ATTACK",
        character = "IRONCLAD",
        rarity = "COMMON",
        damage = 14,
        strengthMultiplier = 3,
        description = "Deal 14 damage. Strength affects this card 3 times.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            -- Request context collection
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Push events with lazy-evaluated fields
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.strengthMultiplier = 5
            self.description = "Deal 14 damage. Strength affects this card 5 times."
        end
    }
}
