return {
    WindmillStrike = {
        id = "WindmillStrike",
        name = "Windmill Strike",
        cost = 2,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "Deal 7 damage. Retain. When Retained, increase this card's damage by 4 this combat.",
        retain = true,
        damage = 7,
        damageGainOnRetain = 4,

        onPlay = function(self, world, player)
            local ContextValidators = require("Utils.ContextValidators")

            -- Request enemy target
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
        end,

        -- Called when card is retained at end of turn
        onRetained = function(self, world, player)
            -- Increase damage permanently for this combat
            local damageGain = self.damageGainOnRetain or 0
            self.damage = self.damage + damageGain

            table.insert(world.log, self.name .. " damage increased to " .. self.damage .. " (+" .. damageGain .. ")")
        end,

        onUpgrade = function(self)
            self.damage = 10
            self.damageGainOnRetain = 5
            self.description = "Deal 10 damage. Retain. When Retained, increase this card's damage by 5 this combat."
            self.upgraded = true
        end
    }
}
