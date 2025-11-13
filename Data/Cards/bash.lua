local ContextValidators = require("Utils.ContextValidators")

return {
    Bash = {
        id = "Bash",
        name = "Bash",
        cost = 1,
        type = "ATTACK",
        character = "IRONCLAD",
        rarity = "STARTER",
        damage = 8,
        vulnerable = 2,
        description = "Deal 8 damage. Apply 2 Vulnerable.",
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

            -- Push status effect with lazy-evaluated target
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = function() return world.combat.stableContext end,
                effectType = "Vulnerable",
                amount = self.vulnerable,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.damage = 10
            self.vulnerable = 3
            self.description = "Deal 10 damage. Apply 3 Vulnerable."
        end
    }
}
