-- DUALCAST
-- Skill: Evoke your next Orb twice.
return {
    Dualcast = {
        id = "Dualcast",
        name = "Dualcast",
        cost = 1,
        type = "SKILL",
        character = "DEFECT",
        rarity = "COMMON",
        upgraded = false,
        description = "Evoke your next Orb twice.",

        onPlay = function(self, world, player)
            -- Evoke leftmost orb twice
            world.queue:push({
                type = "ON_EVOKE_ORB",
                index = 1,  -- Leftmost
                count = 2   -- Trigger twice before removing
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.cost = 0
            self.description = "Evoke your next Orb twice."
        end
    }
}
