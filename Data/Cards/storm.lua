-- STORM
-- Power: Whenever you play a Power, Channel 1 Lightning
return {
    Storm = {
        id = "Storm",
        name = "Storm",
        cost = 1,
        type = "POWER",
        character = "DEFECT",
        rarity = "UNCOMMON",
        upgraded = false,
        description = "Whenever you play a Power card, Channel 1 Lightning.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                status = "storm",
                amount = 1
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.cost = 0
            self.description = "Whenever you play a Power card, Channel 1 Lightning."
        end
    }
}
