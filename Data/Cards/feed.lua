return {
    Feed = {
        id = "Feed",
        name = "Feed",
        cost = 1,
        type = "ATTACK",
        character = "IRONCLAD",
        rarity = "UNCOMMON",
        damage = 10,
        healAmount = 5,
        maxHpGain = 3,
        exhausts = true,
        feedEffect = true,  -- Tag for Death pipeline to recognize on-kill healing
        description = "Deal 10 damage. If Fatal, heal 5 and raise your Max HP by 3. Exhaust.",

        onPlay = function(self, world, player)
            -- Request context collection
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Push damage event with lazy-evaluated defender
            -- Death pipeline will automatically trigger healing if this kills the target
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.damage = 12
            self.healAmount = 5
            self.maxHpGain = 4
            self.description = "Deal 12 damage. If Fatal, heal 5 and raise your Max HP by 4. Exhaust."
        end
    }
}
