return {
    Eruption = {
        id = "Eruption",
        name = "Eruption",
        cost = 2,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "STARTER",
        description = "Deal 9 damage. Enter Wrath.",
        damage = 9,

        onPlay = function(self, world, player)
            -- Collect target context
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

            -- Enter Wrath stance
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = "Wrath"
            })
        end,

        onUpgrade = function(self)
            self.cost = 1
            self.description = "Deal 9 damage. Enter Wrath."
            self.upgraded = true
        end
    }
}
