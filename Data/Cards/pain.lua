-- Pain (Curse)
-- Unplayable. When you exhaust this card, lose 1 HP.

return {
    Pain = {
        id = "Pain",
        name = "Pain",
        cost = -2,  -- Unplayable
        type = "CURSE",
        character = "CURSE",
        rarity = "CURSE",
        description = "Unplayable. When you exhaust this card, lose 1 HP.",

        -- Unplayable flag
        isPlayable = function(self, world, player)
            return false, "Pain is unplayable"
        end,

        -- Hook for onExhaust (would need to be implemented in the combat engine)
        onExhaust = function(self, world, player)
            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = self,
                target = player,
                amount = 1,
                tags = {"ignoreBlock"}
            })
            table.insert(world.log, player.name .. " loses 1 HP from Pain!")
        end
    }
}
