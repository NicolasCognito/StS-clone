local ContextValidators = require("Utils.ContextValidators")

return {
    LessonLearned = {
        id = "LessonLearned",
        name = "Lesson Learned",
        cost = 2,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "RARE",
        damage = 10,
        exhausts = true,
        lessonLearnedEffect = true,  -- Tag for Death pipeline to recognize on-kill upgrade
        description = "Deal 10 damage. If Fatal, Upgrade a random card in your deck. Exhaust.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            -- Request context collection
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Push damage event with lazy-evaluated defender
            -- Death pipeline will automatically trigger upgrade if this kills the target
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.damage = 13
            self.description = "Deal 13 damage. If Fatal, Upgrade a random card in your deck. Exhaust."
        end
    }
}
