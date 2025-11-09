-- Terrify: Apply Vulnerable to ALL enemies
-- Tests the AOE status effect pipeline (target = "all")
-- Demonstrates multi-target debuff application

return {
    Terrify = {
        id = "Terrify",
        name = "Terrify",
        cost = 1,
        type = "SKILL",
        rarity = "UNCOMMON",
        description = "Apply 2 Vulnerable to ALL enemies.",
        keywords = {"Vulnerable"},
        upgraded = false,

        onPlay = function(self, world, player, context)
            -- Apply vulnerable to all enemies using AOE
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = "all",  -- AOE wrapper - targets all enemies
                effectType = "Vulnerable",
                amount = 2,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.name = "Terrify+"
            self.description = "Apply 3 Vulnerable to ALL enemies."

            -- Modify the onPlay to apply 3 Vulnerable instead of 2
            self.onPlay = function(self, world, player, context)
                world.queue:push({
                    type = "ON_STATUS_GAIN",
                    target = "all",
                    effectType = "Vulnerable",
                    amount = 3,
                    source = self
                })
            end
        end
    }
}
