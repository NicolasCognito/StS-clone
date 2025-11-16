return {
    BallLightning = {
        id = "BallLightning",
        name = "Ball Lightning",
        cost = 1,
        type = "ATTACK",
        character = "DEFECT",
        rarity = "COMMON",
        damage = 7,
        strengthMultiplier = 1,
        description = "Deal 7 damage. Channel 1 Lightning.",

        stableContextValidator = require("Utils.ContextValidators").specificEnemyAlive,

        onPlay = function(self, world, player)
            -- Request enemy target
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Deal damage
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })

            -- Channel Lightning
            world.queue:push({
                type = "ON_CHANNEL_ORB",
                orbType = "Lightning"
            })
        end,

        onUpgrade = function(self)
            self.damage = 10
            self.description = "Deal 10 damage. Channel 1 Lightning."
        end
    }
}
