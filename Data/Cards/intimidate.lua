-- Intimidate: Apply Weak to ALL enemies
-- Tests the AOE status effect pipeline (target = "all")
-- Similar to Whirlwind but for status effects instead of damage

return {
    Intimidate = {
        id = "Intimidate",
        name = "Intimidate",
        cost = 0,
        type = "SKILL",
        character = "IRONCLAD",
        rarity = "UNCOMMON",
        description = "Apply 1 Weak to ALL enemies.",
        keywords = {"Weak"},
        upgraded = false,

        onPlay = function(self, world, player, context)
            -- Apply weak to all enemies using AOE
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = "all",  -- AOE wrapper - targets all enemies
                effectType = "Weak",
                amount = 1,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.name = "Intimidate+"
            self.description = "Apply 2 Weak to ALL enemies."

            -- Modify the onPlay to apply 2 Weak instead of 1
            self.onPlay = function(self, world, player, context)
                world.queue:push({
                    type = "ON_STATUS_GAIN",
                    target = "all",
                    effectType = "Weak",
                    amount = 2,
                    source = self
                })
            end
        end
    }
}
