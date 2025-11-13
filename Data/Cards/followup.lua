return {
    FollowUp = {
        id = "FollowUp",
        name = "Follow-Up",
        cost = 1,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "COMMON",
        damage = 7,
        description = "Deal 7 damage. If the last card played was an Attack, gain [E].",

        onPlay = function(self, world, player)
            -- Request enemy target (stable context)
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "enemies",
                    stability = "stable",
                    source = "combat",
                    count = {min = 1, max = 1},
                    filter = function(_, _, _, candidate)
                        return candidate.hp > 0
                    end
                }
            }, "FIRST")

            -- Deal damage
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = world.combat.stableContext,
                card = self
            })

            -- Check if last played card was an Attack, and gain energy if so
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    if world.lastPlayedCard and world.lastPlayedCard.type == "ATTACK" then
                        player.energy = player.energy + 1
                        table.insert(world.log, "Follow-Up grants 1 Energy (last card was an Attack)")
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.damage = 11
            self.description = "Deal 11 damage. If the last card played was an Attack, gain [E]."
        end
    }
}
