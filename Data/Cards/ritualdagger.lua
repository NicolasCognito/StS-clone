local ContextValidators = require("Utils.ContextValidators")

return {
    RitualDagger = {
        id = "RitualDagger",
        name = "Ritual Dagger",
        cost = 1,
        type = "ATTACK",
        character = "COLORLESS",
        rarity = "SPECIAL",
        damage = 15,
        damageIncrease = 3,  -- Per-kill bonus (changes to 5 when upgraded)
        exhausts = true,
        ritualDaggerEffect = true,  -- Tag for Death pipeline to recognize on-kill damage increase
        description = "Deal 15 damage. If Fatal, permanently increase this card's damage by 3. Exhaust.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            -- Request context collection
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Push damage event with lazy-evaluated defender
            -- Death pipeline will automatically increase damage if this kills the target
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.damageIncrease = 5
            self.description = "Deal " .. self.damage .. " damage. If Fatal, permanently increase this card's damage by 5. Exhaust."
        end
    }
}
