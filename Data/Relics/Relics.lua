-- RELICS DATA
-- Relic definitions with their effects
-- Each relic has:
-- - Data parameters (healAmount, triggerFlags, etc)
-- - onEndCombat: pushes event to queue at end of combat

local Relics = {
    BurningBlood = {
        id = "Burning_Blood",
        name = "Burning Blood",
        rarity = "STARTER",
        description = "At the end of combat, heal 6 HP.",
        healAmount = 6,

        onEndCombat = function(self, world, player)
            world.queue:push({
                type = "ON_HEAL",
                target = player,
                relic = self
            })
        end
    },

    PaperPhrog = {
        id = "Paper_Phrog",
        name = "Paper Phrog",
        rarity = "UNCOMMON",
        description = "Enemies with Vulnerable take 75% more damage rather than 50%.",
        -- Passive relic - no delta functions needed
        -- Effect is hardcoded in DealDamage pipeline
    },

    SneckoEye = {
        id = "Snecko_Eye",
        name = "Snecko Eye",
        rarity = "BOSS",
        description = "Draw 2 additional cards each turn. Start each combat Confused.",
        -- Passive relic - Confused status applied at combat start in main.lua
        -- Draw effect would be in StartTurn pipeline (not implemented yet)
    },
  
    TheBoot = {
        id = "The_Boot",
        name = "The Boot",
        rarity = "COMMON",
        description = "Whenever you would deal 4 or less unblocked Attack damage, increase it to 5. Bypasses Intangible.",
        -- Passive relic - no delta functions needed
        -- Effect is hardcoded in DealDamage pipeline
    },

    WingedBoots = {
        id = "Winged_Boots",
        name = "Winged Boots",
        rarity = "RARE",
        description = "You may ignore paths and choose any room on the next floor 3 times.",
        -- Passive relic - logic is in ChooseNextNode pipeline
        -- Charges tracked in world.wingedBootsCharges (set to 3 when player has this relic)
        -- Cannot choose same floor, skip floors, or go back
        -- Only works when moving to next floor
    }
}

return Relics
