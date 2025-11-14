return {
    CrushJoints = {
        id = "CrushJoints",
        name = "Crush Joints",
        cost = 1,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "COMMON",
        damage = 8,
        description = "Deal 8 damage. If the last card played was a Skill, apply 1 Vulnerable.",

        onPlay = function(self, world, player)
            -- Request enemy target (stable context)
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

            -- Check if last played card was a Skill, and apply Vulnerable if so
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    if world.lastPlayedCard and world.lastPlayedCard.type == "SKILL" then
                        local target = world.combat.stableContext
                        if target and target.hp > 0 then
                            local vulnerableStacks = self.vulnerableStacks or 1
                            world.queue:push({
                                type = "ON_STATUS_GAIN",
                                target = target,
                                effectType = "Vulnerable",
                                amount = vulnerableStacks
                            })
                        end
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.damage = 10
            self.description = "Deal 10 damage. If the last card played was a Skill, apply 2 Vulnerable."
            self.vulnerableStacks = 2
        end
    }
}
