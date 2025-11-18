-- Slimed (Status)
-- Exhaust. (Costs 1 energy)
-- The ONLY playable Status card!
-- Status card added by slime enemies (Acid Slime, Spike Slime, Slime Boss, Time Eater, Corrupt Heart)

return {
    Slimed = {
        id = "Slimed",
        name = "Slimed",
        cost = 1,  -- PLAYABLE! (unique among Status cards)
        type = "STATUS",
        character = "COLORLESS",
        rarity = "COMMON",
        exhausts = true,
        description = "Exhaust.",

        -- onPlay: Does nothing except exhaust (handled by exhaust property)
        onPlay = function(self, world, player, target)
            -- No effect - just wastes 1 energy and exhausts
        end,

        -- No onUpgrade function - Slimed cannot be upgraded
    }
}
