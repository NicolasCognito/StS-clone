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
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    },

    weak = {
        id = "weak",
        name = "Weak",
        description = "Deal 25% less damage with attacks",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    },

    frail = {
        id = "frail",
        name = "Frail",
        description = "Gain 25% less block from cards",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    },

    poison = {
        id = "poison",
        name = "Poison",
        description = "Lose HP at the end of turn, then reduce by 1",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = true
    },

    thorns = {
        id = "thorns",
        name = "Thorns",
        description = "Deal damage back to attackers",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    },

    intangible = {
        id = "intangible",
        name = "Intangible",
        description = "Damage received is reduced to 1",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = false,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    },

    confused = {
        id = "confused",
        name = "Confused",
        description = "Card costs are randomized between 0 and 3",
        minValue = 0,
        maxValue = 1,
        stackType = "intensity",
        debuff = true
    },

    strength = {
        id = "strength",
        name = "Strength",
        description = "Increases attack damage (can be negative)",
        minValue = -999,  -- Can be negative
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    },

    dexterity = {
        id = "dexterity",
        name = "Dexterity",
        description = "Increases block gain (can be negative)",
        minValue = -999,  -- Can be negative
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    },

    focus = {
        id = "focus",
        name = "Focus",
        description = "Increases orb effectiveness (can be negative)",
        minValue = -999,  -- Can be negative
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    },

    artifact = {
        id = "artifact",
        name = "Artifact",
        description = "Negate next debuff",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    },

    plated_armor = {
        id = "plated_armor",
        name = "Plated Armor",
        description = "Gain block at end of turn",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    },

    ritual = {
        id = "ritual",
        name = "Ritual",
        description = "Gain strength at end of turn",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    },

    regeneration = {
        id = "regeneration",
        name = "Regeneration",
        description = "Heal HP at end of turn",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    },

    metallicize = {
        id = "metallicize",
        name = "Metallicize",
        description = "Gain block at end of turn",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    },

    buffer = {
        id = "buffer",
        name = "Buffer",
        description = "Prevent next instance of HP loss",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    },

    entangled = {
        id = "entangled",
        name = "Entangled",
        description = "Cannot play attacks",
        minValue = 0,
        maxValue = 1,
        stackType = "duration",
        debuff = true
    },

    blur = {
        id = "blur",
        name = "Blur",
        description = "Block is not removed at start of turn",
        minValue = 0,
        maxValue = 1,  -- Binary effect
        stackType = "intensity",
        debuff = false,
        goesDownOnRoundEnd = true,
        roundEndMode = "WoreOff"
    },

    no_draw = {
        id = "no_draw",
        name = "No Draw",
        description = "Cannot draw cards this turn",
        minValue = 0,
        maxValue = 1,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    },

    block_return = {
        id = "block_return",
        name = "Block Return",
        description = "When you deal attack damage, the target gains Block",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "WoreOff"
    },

    shackled = {
        id = "shackled",
        name = "Shackled",
        description = "Gain that much Strength at start of turn, then remove",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true
    },

    slow = {
        id = "slow",
        name = "Slow",
        description = "Take 10% more attack damage per stack this turn",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "WoreOff"
    },

    draw_reduction = {
        id = "draw_reduction",
        name = "Draw Reduction",
        description = "Draw fewer cards next draw phase",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "WoreOff"
    },

    no_block = {
        id = "no_block",
        name = "No Block",
        description = "Cannot gain Block",
        minValue = 0,
        maxValue = 1,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    },

    constricted = {
        id = "constricted",
        name = "Constricted",
        description = "Take damage at end of turn equal to stacks",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = true
    },

    corpse_explosion = {
        id = "corpse_explosion",
        name = "Corpse Explosion",
        description = "On death, deal stacks times max HP damage to all enemies",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = true
    },

    choked = {
        id = "choked",
        name = "Choked",
        description = "Whenever you play a card, take damage",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = true
    },

    bias = {
        id = "bias",
        name = "Bias",
        description = "Lose 1 Focus each turn",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true
    },

    hex = {
        id = "hex",
        name = "Hex",
        description = "Add Dazed to draw pile when playing non-attack cards",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true
    },

    lock_on = {
        id = "lock_on",
        name = "Lock-On",
        description = "Orbs deal 50% more damage to this target",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    },

    mark = {
        id = "mark",
        name = "Mark",
        description = "Lose HP when triggered by Pressure Points",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = true
    },

    fasting = {
        id = "fasting",
        name = "Fasting",
        description = "Lose 1 energy at start of turn per stack",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = true
    },

    wraith_form = {
        id = "wraith_form",
        name = "Wraith Form",
        description = "Lose 1 Dexterity at end of turn per stack",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true
    },

    barricade = {
        id = "barricade",
        name = "Barricade",
        description = "Block is not removed at end of round",
        minValue = 0,
        maxValue = 1,
        stackType = "intensity",
        debuff = false
    },

    corruption = {
        id = "corruption",
        name = "Corruption",
        description = "Skills cost 0. Whenever you play a Skill, Exhaust it.",
        minValue = 0,
        maxValue = 1,
        stackType = "intensity",
        debuff = false
    },

    echo_form = {
        id = "echo_form",
        name = "Echo Form",
        description = "The first N cards you play each turn are played twice.",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    },

    master_reality = {
        id = "master_reality",
        name = "Master Reality",
        description = "Whenever a card is created during combat, Upgrade it.",
        minValue = 0,
        maxValue = 1,
        stackType = "intensity",
        debuff = false
    },

    establishment = {
        id = "establishment",
        name = "Establishment",
        description = "Whenever you Retain a card, reduce its cost by 1.",
        minValue = 0,
        maxValue = 1,
        stackType = "intensity",
        debuff = false
    },

    -- ORB-RELATED STATUS EFFECTS

    static_discharge = {
        id = "static_discharge",
        name = "Static Discharge",
        description = "Whenever you take attack damage, Channel that many Lightning.",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    },

    storm = {
        id = "storm",
        name = "Storm",
        description = "Whenever you play a Power card, Channel 1 Lightning.",
        minValue = 0,
        maxValue = 1,
        stackType = "intensity",
        debuff = false
    },

    electrodynamics = {
        id = "electrodynamics",
        name = "Electrodynamics",
        description = "Lightning Orbs now hit ALL enemies.",
        minValue = 0,
        maxValue = 1,
        stackType = "intensity",
        debuff = false
    },

    loop = {
        id = "loop",
        name = "Loop",
        description = "At the start of your turn, trigger your next Orb's passive N times.",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    }
}

return StatusEffects
