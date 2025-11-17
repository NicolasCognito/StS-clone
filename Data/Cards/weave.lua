local ContextValidators = require("Utils.ContextValidators")

return {
    Weave = {
        id = "Weave",
        name = "Weave",
        cost = 0,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "UNCOMMON",
        damage = 4,
        description = "Deal 4 damage. Whenever you Scry, return this from the discard pile to your hand.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.damage = 6
            self.description = "Deal 6 damage. Whenever you Scry, return this from the discard pile to your hand."
        end
    }
}
