-- BARRAGE
-- Attack: Deal 4 damage per channeled Orb.
local ContextValidators = require("Utils.ContextValidators")

return {
    Barrage = {
        id = "Barrage",
        name = "Barrage",
        cost = 1,
        type = "ATTACK",
        character = "DEFECT",
        rarity = "COMMON",
        upgraded = false,
        description = "Deal 4 damage per channeled Orb.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            local damagePerOrb = self.upgraded and 6 or 4
            local orbCount = #player.orbs
            local totalDamage = damagePerOrb * orbCount

            -- Request target
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "enemy",
                    stability = "stable"
                }
            }, "FIRST")

            -- Deal damage (override card's damage for this play)
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local originalDamage = self.damage
                    self.damage = totalDamage

                    world.queue:push({
                        type = "ON_ATTACK_DAMAGE",
                        attacker = player,
                        defender = function() return world.combat.stableContext end,
                        card = self
                    })

                    self.damage = originalDamage
                end
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Deal 6 damage per channeled Orb."
        end
    }
}
