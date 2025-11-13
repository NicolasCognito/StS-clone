local ContextValidators = require("Utils.ContextValidators")

return {
    FlurryOfBlows = {
        id = "FlurryOfBlows",
        name = "Flurry of Blows",
        cost = 0,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "COMMON",
        damage = 4,
        description = "Deal 4 damage. Whenever you change your stance, return this card from your discard pile to your hand.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            -- Request context collection
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Push damage event with lazy-evaluated defender
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.damage = 6
            self.description = "Deal 6 damage. Whenever you change your stance, return this card from your discard pile to your hand."
        end
    }
}
