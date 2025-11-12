-- STATUS EFFECTS DATA
-- Defines all status effects and their constraints
--
-- Each status effect has:
-- - id: unique identifier (lowercase, matches status table key)
-- - name: display name
-- - description: effect description
-- - minValue: minimum value (floor), default 0
-- - maxValue: maximum value (cap), default 999
-- - debuff: true if this is a negative effect, false if positive
--
-- Special stats (HP, Block) are handled in ApplyCaps pipeline directly

local StatusEffects = {
    vulnerable = {
        id = "vulnerable",
        name = "Vulnerable",
        description = "Take 50% more damage from attacks (75% with Paper Phrog)",
        minValue = 0,
        maxValue = 999,
        debuff = true
    },

    weak = {
        id = "weak",
        name = "Weak",
        description = "Deal 25% less damage with attacks",
        minValue = 0,
        maxValue = 999,
        debuff = true
    },

    frail = {
        id = "frail",
        name = "Frail",
        description = "Gain 25% less block from cards",
        minValue = 0,
        maxValue = 999,
        debuff = true
    },

    poison = {
        id = "poison",
        name = "Poison",
        description = "Lose HP at the end of turn, then reduce by 1",
        minValue = 0,
        maxValue = 999,
        debuff = true
    },

    thorns = {
        id = "thorns",
        name = "Thorns",
        description = "Deal damage back to attackers",
        minValue = 0,
        maxValue = 999,
        debuff = false
    },

    intangible = {
        id = "intangible",
        name = "Intangible",
        description = "Damage received is reduced to 1",
        minValue = 0,
        maxValue = 999,
        debuff = false
    },

    confused = {
        id = "confused",
        name = "Confused",
        description = "Card costs are randomized between 0 and 3",
        minValue = 0,
        maxValue = 999,
        debuff = true
    },

    strength = {
        id = "strength",
        name = "Strength",
        description = "Increases attack damage (can be negative)",
        minValue = -999,  -- Can be negative
        maxValue = 999,
        debuff = false
    },

    dexterity = {
        id = "dexterity",
        name = "Dexterity",
        description = "Increases block gain (can be negative)",
        minValue = -999,  -- Can be negative
        maxValue = 999,
        debuff = false
    },

    focus = {
        id = "focus",
        name = "Focus",
        description = "Increases orb effectiveness (can be negative)",
        minValue = -999,  -- Can be negative
        maxValue = 999,
        debuff = false
    },

    artifact = {
        id = "artifact",
        name = "Artifact",
        description = "Negate next debuff",
        minValue = 0,
        maxValue = 999,
        debuff = false
    },

    plated_armor = {
        id = "plated_armor",
        name = "Plated Armor",
        description = "Gain block at end of turn",
        minValue = 0,
        maxValue = 999,
        debuff = false
    },

    ritual = {
        id = "ritual",
        name = "Ritual",
        description = "Gain strength at end of turn",
        minValue = 0,
        maxValue = 999,
        debuff = false
    },

    regeneration = {
        id = "regeneration",
        name = "Regeneration",
        description = "Heal HP at end of turn",
        minValue = 0,
        maxValue = 999,
        debuff = false
    },

    metallicize = {
        id = "metallicize",
        name = "Metallicize",
        description = "Gain block at end of turn",
        minValue = 0,
        maxValue = 999,
        debuff = false
    },

    buffer = {
        id = "buffer",
        name = "Buffer",
        description = "Prevent next instance of HP loss",
        minValue = 0,
        maxValue = 999,
        debuff = false
    },

    entangled = {
        id = "entangled",
        name = "Entangled",
        description = "Cannot play attacks",
        minValue = 0,
        maxValue = 999,
        debuff = true
    },

    blur = {
        id = "blur",
        name = "Blur",
        description = "Block is not removed at start of turn",
        minValue = 0,
        maxValue = 1,  -- Binary effect
        debuff = false
    }
}

return StatusEffects
