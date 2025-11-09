-- WORLD STATE
-- Persistent game data (player, map, relic charges, etc.)
-- Combat-only context (queue/log/counters) is attached temporarily per encounter
-- This module intentionally stays logic-free; it should only shape state containers.

local World = {}

function World.createWorld(playerData)
    return {
        player = {
            -- Identity
            id = playerData.id or "IronClad",
            name = playerData.name or playerData.id or "IronClad",

            -- HP
            maxHp = playerData.maxHp or 80,
            currentHp = playerData.currentHp or playerData.maxHp or 80,
            hp = playerData.currentHp or playerData.maxHp or 80,
            block = 0,

            -- Energy
            energy = 3,
            maxEnergy = 3,

            -- MASTER DECK (Persistent across combats)
            -- The player's permanent card collection. Modified by:
            -- - Card rewards after combat (AcquireCard pipeline outside combat)
            -- - Shop card purchases/removals
            -- - Rest site upgrades
            -- - Permanent transforms/removals (events, relics, etc.)
            -- This deck persists across all combats and represents the player's "true" deck.
            masterDeck = playerData.masterDeck or playerData.cards or {},

            -- COMBAT DECK (Temporary, created at combat start)
            -- Deep copy of masterDeck created when combat begins (StartCombat pipeline).
            -- Modified by temporary effects during combat only:
            -- - Generated/created cards (potions, Infernal Blade, etc.)
            -- - Temporary upgrades (Apotheosis card)
            -- - Combat-only card modifications
            -- - All cards have card.state property: "DECK", "HAND", "DISCARD_PILE", "EXHAUSTED_PILE"
            -- This deck is discarded when combat ends (EndCombat pipeline).
            -- Outside combat, this is nil.
            combatDeck = nil,

            -- Relics & gold
            relics = playerData.relics or {},
            gold = playerData.gold or 0,

            -- Combat-only state (status effects, powers)
            status = nil,
            powers = nil
        },

        -- Current encounter enemies (array or nil outside combat)
        enemies = nil,

        -- Map traversal metadata
        map = playerData.map or nil,
        currentNode = playerData.startNode or nil,
        floor = playerData.floor or 1,

        -- Relic state (persists across fights)
        -- Winged Boots state (managed by AcquireRelic/LoseRelic pipelines)
        wingedBootsCharges = playerData.wingedBootsCharges or 0,
        -- Pen Nib counter (increments each Attack played, resets after 10th)
        penNibCounter = playerData.penNibCounter or 0
    }
end

return World
