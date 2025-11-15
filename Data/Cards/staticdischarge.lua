-- STATIC DISCHARGE
-- Power: Whenever you take attack damage, Channel Lightning
return {
    StaticDischarge = {
        id = "Static_Discharge",
        name = "Static Discharge",
        cost = 1,
        type = "POWER",
        character = "DEFECT",
        rarity = "UNCOMMON",
        upgraded = false,
        description = "Whenever you take attack damage, Channel 1 Lightning.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "static_discharge",
                amount = self.upgraded and 2 or 1
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Whenever you take attack damage, Channel 2 Lightning."
        end
    }
}
