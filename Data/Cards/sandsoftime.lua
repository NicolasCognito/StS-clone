return {
    SandsOfTime = {
        id = "SandsOfTime",
        name = "Sands of Time",
        cost = 4,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "Deal 20 damage. Retain. When Retained, reduce this card's cost by 1 this combat.",
        retain = true,
        damage = 20,
        costReductionPerRetain = 1,  -- Uses existing GetCost mechanism

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

        onUpgrade = function(self)
            self.damage = 26
            self.description = "Deal 26 damage. Retain. When Retained, reduce this card's cost by 1 this combat."
            self.upgraded = true
        end
    }
}
