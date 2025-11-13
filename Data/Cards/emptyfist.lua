return {
    EmptyFist = {
        id = "EmptyFist",
        name = "Empty Fist",
        cost = 1,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "COMMON",
        description = "Deal 9 damage. Exit your stance.",
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

            -- Exit stance (set to nil for neutral)
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = nil
            })
        end,

        onUpgrade = function(self)
            self.damage = 14
            self.description = "Deal 14 damage. Exit your stance."
            self.upgraded = true
        end
    }
}
