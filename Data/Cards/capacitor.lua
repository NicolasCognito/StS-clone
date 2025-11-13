-- CAPACITOR
-- Power: Gain 2 Orb slots.
return {
    Capacitor = {
        id = "Capacitor",
        name = "Capacitor",
        cost = 1,
        type = "POWER",
        character = "DEFECT",
        rarity = "UNCOMMON",
        upgraded = false,
        description = "Gain 2 Orb slots.",

        onPlay = function(self, world, player)
            local slotGain = self.upgraded and 3 or 2

            -- Gain orb slots via custom effect
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    player.maxOrbs = player.maxOrbs + slotGain
                    table.insert(world.log, player.name .. " gained " .. slotGain .. " orb slots")
                end
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Gain 3 Orb slots."
        end
    }
}
