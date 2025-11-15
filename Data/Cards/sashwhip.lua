return {
    SashWhip = {
        id = "SashWhip",
        name = "Sash Whip",
        cost = 1,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "COMMON",
        damage = 8,
        description = "Deal 8 damage. If the last card played was an Attack, apply 1 Weak.",

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

            -- Check if last played card was an Attack, and apply Weak if so
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local cardsPlayed = world.combat.cardsPlayedThisTurn
                    if #cardsPlayed > 0 and cardsPlayed[#cardsPlayed].type == "ATTACK" then
                        local target = world.combat.stableContext
                        if target and target.hp > 0 then
                            local weakStacks = self.weakStacks or 1
                            world.queue:push({
                                type = "ON_STATUS_GAIN",
                                target = target,
                                effectType = "Weak",
                                amount = weakStacks
                            })
                        end
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.damage = 10
            self.description = "Deal 10 damage. If the last card played was an Attack, apply 2 Weak."
            self.weakStacks = 2
        end
    }
}
