-- MULTI-CAST
-- Skill (X-cost): Evoke your next Orb X times.
return {
    MultiCast = {
        id = "Multi_Cast",
        name = "Multi-Cast",
        cost = "X",
        type = "SKILL",
        character = "DEFECT",
        rarity = "RARE",
        upgraded = false,
        description = "Evoke your next Orb X times.",

        onPlay = function(self, world, player)
            local evokes = self.energySpent or 0
            if self.upgraded then
                evokes = evokes + 1
            end

            -- Evoke leftmost orb X times
            for i = 1, evokes do
                world.queue:push({
                    type = "ON_EVOKE_ORB",
                    index = 1  -- Always leftmost
                })
            end
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Evoke your next Orb X+1 times."
        end
    }
}
