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
            for i = 1, 2 do
                world.queue:push({
                    type = "ON_EVOKE_ORB",
                    index = 1  -- Always leftmost
                })
            end
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.cost = 0
            self.description = "Evoke your next Orb twice."
        end
    }
}
