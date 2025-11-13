-- CONSUME
-- Skill: Gain 2 Focus. Lose 1 Orb slot.
return {
    Consume = {
        id = "Consume",
        name = "Consume",
        cost = 2,
        type = "SKILL",
        character = "DEFECT",
        rarity = "RARE",
        upgraded = false,
        description = "Gain 2 Focus. Lose 1 Orb slot.",

        onPlay = function(self, world, player)
            local focusGain = self.upgraded and 3 or 2

            -- Gain Focus
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                status = "focus",
                amount = focusGain
            })

            -- Lose 1 Orb slot via custom effect
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    if player.maxOrbs > 0 then
                        -- Remove leftmost orb slot (and orb if present, WITHOUT evoking)
                        if #player.orbs > 0 then
                            table.remove(player.orbs, 1)
                            table.insert(world.log, "Leftmost orb was consumed!")
                        end

                        player.maxOrbs = player.maxOrbs - 1
                        table.insert(world.log, player.name .. " lost 1 orb slot")
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Gain 3 Focus. Lose 1 Orb slot."
        end
    }
}
