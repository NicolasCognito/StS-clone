-- Burn (Status)
-- Unplayable. At the end of your turn, take 2 (4) damage.
-- Status card added by certain enemies (Sentry, Awakened One, Corrupt Heart)

return {
    Burn = {
        id = "Burn",
        name = "Burn",
        cost = -2,  -- Unplayable
        type = "STATUS",
        character = "COLORLESS",
        rarity = "COMMON",
        unplayable = true,
        damage = 2,
        description = "Unplayable. At the end of your turn, take 2 damage.",

        -- Hook triggered at end of turn (handled by EndTurn pipeline)
        onEndOfTurn = function(self, world, player)
            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = self,
                target = player,
                amount = self.damage,
                tags = {"ignoreBlock"}  -- HP loss bypasses block
            })
            table.insert(world.log, player.name .. " takes " .. self.damage .. " damage from Burn!")
        end,

        -- No onPlay function - this card cannot be played (unless Medical Kit relic is equipped)

        -- Burn can be upgraded!
        onUpgrade = function(self)
            self.damage = 4
            self.description = "Unplayable. At the end of your turn, take 4 damage."
        end
    }
}
