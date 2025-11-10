-- Decay (Curse)
-- Unplayable. At the end of your turn, lose 2 HP.

return {
    Decay = {
        id = "Decay",
        name = "Decay",
        cost = -2,  -- Unplayable
        type = "CURSE",
        character = "CURSE",
        rarity = "CURSE",
        description = "Unplayable. At the end of your turn, lose 2 HP.",

        -- Unplayable flag
        isPlayable = function(self, world, player)
            return false, "Decay is unplayable"
        end,

        -- Hook for end of turn (would need to be checked in EndTurn pipeline)
        onEndOfTurn = function(self, world, player)
            -- Only trigger if this card is in hand at end of turn
            if self.state == "HAND" then
                world.queue:push({
                    type = "ON_NON_ATTACK_DAMAGE",
                    source = self,
                    target = player,
                    amount = 2,
                    tags = {"ignoreBlock"}
                })
                table.insert(world.log, player.name .. " loses 2 HP from Decay!")
            end
        end
    }
}
