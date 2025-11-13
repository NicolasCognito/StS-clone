local ContextValidators = require("Utils.ContextValidators")

return {
    BloodForBlood = {
        id = "Blood_for_Blood",
        name = "Blood for Blood",
        cost = 4,
        type = "ATTACK",
        character = "IRONCLAD",
        rarity = "UNCOMMON",
        damage = 18,
        costReductionPerHpLoss = 1,  -- Reduces cost by 1 for each time player lost HP
        description = "Deal 18 damage. Costs 1 less for each time you lose HP this combat.",
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
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.cost = 3
            self.damage = 22
            self.description = "Deal 22 damage. Costs 1 less for each time you lose HP this combat."
        end
    }
}
