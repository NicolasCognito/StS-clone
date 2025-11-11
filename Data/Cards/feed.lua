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
        description = "Deal 10 damage. If Fatal, heal 5 and raise your Max HP by 3. Exhaust.",

        onPlay = function(self, world, player)
            -- Request context collection
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Push damage event with lazy-evaluated defender
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })

            -- Push custom effect to check if kill was fatal and trigger healing
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local target = world.combat.stableContext

                    -- Check if the target exists and was killed
                    if target and target.dead then
                        -- Use the Heal pipeline for proper healing + max HP increase
                        world.queue:push({
                            type = "ON_HEAL",
                            target = player,
                            amount = self.healAmount,
                            maxHpIncrease = self.maxHpGain,
                            source = self
                        })
                    end
                end
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
