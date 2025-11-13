-- FISSION
-- Skill: Evoke ALL your Orbs. Gain 1 Energy and draw 1 card per Orb Evoked. Exhaust.
return {
    Fission = {
        id = "Fission",
        name = "Fission",
        cost = 0,
        type = "SKILL",
        character = "DEFECT",
        rarity = "RARE",
        upgraded = false,
        exhausts = true,
        description = "Evoke ALL your Orbs. Gain 1 Energy and draw 1 card per Orb Evoked. Exhaust.",

        onPlay = function(self, world, player)
            local orbCount = #player.orbs

            if orbCount > 0 then
                -- Evoke all orbs
                world.queue:push({
                    type = "ON_EVOKE_ORB",
                    index = "all"
                })

                -- Gain energy and draw cards via custom effect
                world.queue:push({
                    type = "ON_CUSTOM_EFFECT",
                    effect = function()
                        -- Gain energy
                        player.energy = player.energy + orbCount
                        table.insert(world.log, player.name .. " gained " .. orbCount .. " energy from Fission")

                        -- Draw cards
                        for i = 1, orbCount do
                            world.queue:push({type = "ON_DRAW"})
                        end
                    end
                })
            end
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.exhausts = false
            self.description = "Evoke ALL your Orbs. Gain 1 Energy and draw 1 card per Orb Evoked."
        end
    }
}
