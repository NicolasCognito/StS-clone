-- LOOP
-- Power: At the start of your turn, trigger the passive ability of your next Orb
return {
    Loop = {
        id = "Loop",
        name = "Loop",
        cost = 1,
        type = "POWER",
        character = "DEFECT",
        rarity = "UNCOMMON",
        upgraded = false,
        description = "At the start of your turn, trigger the passive ability of your next Orb.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "loop",
                amount = self.upgraded and 2 or 1
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "At the start of your turn, trigger the passive ability of your next Orb twice."
        end
    }
}
