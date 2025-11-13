-- METEOR STRIKE
-- Attack: Deal 24 damage. Channel 3 Plasma.
local ContextValidators = require("Utils.ContextValidators")

return {
    MeteorStrike = {
        id = "Meteor_Strike",
        name = "Meteor Strike",
        cost = 5,
        type = "ATTACK",
        character = "DEFECT",
        rarity = "RARE",
        damage = 24,
        upgraded = false,
        description = "Deal 24 damage. Channel 3 Plasma.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            -- Request target
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "enemy",
                    stability = "stable"
                }
            }, "FIRST")

            -- Deal damage
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })

            -- Channel Plasma orbs
            for i = 1, 3 do
                world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Plasma"})
            end
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.damage = 30
            self.description = "Deal 30 damage. Channel 3 Plasma."
        end
    }
}
