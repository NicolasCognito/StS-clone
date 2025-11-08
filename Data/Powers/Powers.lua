-- POWERS DATA
-- Power definitions for permanent combat buffs/debuffs
-- Powers last the entire combat (or until removed)
--
-- Each power has:
-- - id, name, description
-- - Optional: onTurnStart, onTurnEnd, onCardPlayed, etc.
--
-- Powers are stored in player.powers[] or enemy.powers[]
-- Effects are checked in pipelines (GetCost, PlayCard, etc.)

local Powers = {
    Corruption = {
        id = "Corruption",
        name = "Corruption",
        description = "Skills cost 0. Whenever you play a Skill, Exhaust it.",
        -- Power effect is passive, checked in:
        -- - GetCost pipeline: Skills cost 0
        -- - PlayCard pipeline: Skills are exhausted
    }
}

return Powers
