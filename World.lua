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
            energy = playerData.energy or playerData.maxEnergy or 3,
            maxEnergy = playerData.maxEnergy or 3,

            -- MASTER DECK (Persistent across combats)
            -- The player's permanent card collection. Modified by:
            -- - Card rewards after combat (AcquireCard pipeline outside combat)
            -- - Shop card purchases/removals
            -- - Rest site upgrades
            -- - Permanent transforms/removals (events, relics, etc.)
            -- This deck persists across all combats and represents the player's "true" deck.
            masterDeck = playerData.masterDeck or playerData.cards or {},
            permanentStrength = playerData.permanentStrength or 0,

            -- MASTER POTIONS (Persistent across combats)
            -- Simple consumables that can be used during combat. Unlike cards:
            -- - No masterPotion/combatPotion split - used directly from this table
            -- - No energy cost
            -- - Single-use: removed from this table when used
            -- - No duplication effects (Double Tap, Burst, etc.)
            masterPotions = playerData.masterPotions or {},

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
            powers = nil,

            -- Stance system
            -- currentStance is a string: "Calm", "Wrath", "Divinity", or nil for neutral
            -- All stance logic lives in ChangeStance pipeline (no callbacks)
            currentStance = nil,

            -- Orb system (Defect mechanic)
            -- orbs is an array of orb instances: [{id = "Lightning", baseDamage = 8, ...}, ...]
            -- Index 1 = leftmost orb (evoked first when slots are full)
            -- All orb logic lives in ChannelOrb/EvokeOrb/OrbPassive pipelines
            orbs = playerData.orbs or {},
            maxOrbs = playerData.maxOrbs or 3  -- Default 3 orb slots for Defect
        },

        -- Current encounter enemies (array or nil outside combat)
        enemies = nil,

        -- Map traversal metadata
        map = playerData.map or nil,
        currentNode = playerData.startNode or nil,
        floor = playerData.floor or 1,
        mapQueue = nil, -- Initialized lazily via Map_MapQueue

        -- Relic state (persists across fights)
        -- Winged Boots state (managed by Map_AcquireRelic/Map_LoseRelic pipelines)
        wingedBootsCharges = playerData.wingedBootsCharges or 0,
        -- Pen Nib counter (increments each Attack played, resets after 10th)
        penNibCounter = playerData.penNibCounter or 0,
        pendingRestSiteEnergy = playerData.pendingRestSiteEnergy or 0,
        giryaLiftsUsed = playerData.giryaLiftsUsed or 0,
        rubyKeyObtained = playerData.rubyKeyObtained or false,
        act4Unlocked = playerData.act4Unlocked or false
    }
end

-- COMBAT STATE INITIALIZATION
-- Creates the combat-specific state structure attached to world.combat
-- Called by StartCombat pipeline at the beginning of each combat encounter
-- Cleared by EndCombat pipeline when combat ends
function World.initCombatState()
    return {
        timesHpLost = 0,
        cardsDiscardedThisTurn = 0,
        powersPlayedThisCombat = 0,
        -- Context system
        stableContext = nil,    -- Persists across duplications (e.g., enemy target)
        tempContext = nil,      -- Re-collected on duplications (e.g., card discard)
        contextRequest = nil,   -- Request for context collection: {contextProvider, stability}
        deferStableContextClear = false,
        -- Death tracking
        playerDied = false
    }
end

-- MAP EVENT STATE INITIALIZATION
-- Creates the map event state structure attached to world.mapEvent
-- Called when a map event starts (via MapEngine or pipelines)
-- Cleared by Map_EventComplete pipeline when event ends
-- Parameters:
--   eventKey: The event identifier (optional)
--   eventDef: The event definition table (optional)
function World.initMapEventState(eventKey, eventDef)
    return {
        eventKey = eventKey or nil,
        event = eventDef or nil,
        currentNodeId = eventDef and eventDef.entryNode or nil,
        stableContext = nil,
        tempContext = nil,
        contextRequest = nil,
        deferStableContextClear = false,
        pendingSelection = nil
    }
end

return World
