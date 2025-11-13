-- RECURSION
-- Skill: Evoke your next Orb, then Channel that same Orb.
return {
    Recursion = {
        id = "Recursion",
        name = "Recursion",
        cost = 1,
        type = "SKILL",
        character = "DEFECT",
        rarity = "UNCOMMON",
        upgraded = false,
        description = "Evoke your next Orb, then Channel that same Orb.",

        onPlay = function(self, world, player)
            -- Save the orb type AND state before evoking
            if #player.orbs > 0 then
                local orb = player.orbs[1]  -- Leftmost orb
                local orbType = orb.id

                -- Save Dark orb accumulated damage
                local orbState = nil
                if orbType == "Dark" and orb.accumulatedDamage then
                    orbState = {accumulatedDamage = orb.accumulatedDamage}
                end

                -- Evoke it
                world.queue:push({
                    type = "ON_EVOKE_ORB",
                    index = 1
                })

                -- Channel the same type again (preserving state for Dark orbs)
                world.queue:push({
                    type = "ON_CHANNEL_ORB",
                    orbType = orbType,
                    orbState = orbState
                })
            end
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.cost = 0
            self.description = "Evoke your next Orb, then Channel that same Orb."
        end
    }
}
