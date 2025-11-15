return {
    WellLaidPlans = {
        id = "WellLaidPlans",
        name = "Well-Laid Plans",
        cost = 1,
        type = "POWER",
        character = "SILENT",
        rarity = "UNCOMMON",
        description = "At the end of your turn, Retain up to 1 card.",
	-- Temporary change for testing
        retainCount = 2,

        onPlay = function(self, world, player)
            -- Apply Well-Laid Plans status effect
            -- The power's stacks determine how many cards can be retained
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "well_laid_plans",
                amount = self.retainCount
            })
        end,

        onUpgrade = function(self)
            self.retainCount = 2
            self.description = "At the end of your turn, Retain up to 2 cards."
            self.upgraded = true
        end
    }
}
