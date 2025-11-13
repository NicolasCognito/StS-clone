-- THUNDER STRIKE
-- Attack: Deal damage to a random enemy for each Lightning channeled this combat.
return {
    ThunderStrike = {
        id = "Thunder_Strike",
        name = "Thunder Strike",
        cost = 3,
        type = "ATTACK",
        character = "DEFECT",
        rarity = "RARE",
        damage = 7,
        upgraded = false,
        description = "Deal 7 damage to a random enemy for each Lightning channeled this combat.",

        onPlay = function(self, world, player)
            local Utils = require("utils")
            local lightningCount = world.combat.lightningChanneledThisCombat or 0

            -- Deal damage to random enemy for each Lightning
            for i = 1, lightningCount do
                world.queue:push({
                    type = "ON_CUSTOM_EFFECT",
                    effect = function()
                        local target = Utils.randomEnemy(world)
                        if target then
                            world.queue:push({
                                type = "ON_ATTACK_DAMAGE",
                                attacker = player,
                                defender = target,
                                card = self
                            })
                        end
                    end
                })
            end
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.damage = 9
            self.description = "Deal 9 damage to a random enemy for each Lightning channeled this combat."
        end
    }
}
