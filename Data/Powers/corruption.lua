return {
    Corruption = {
        id = "Corruption",
        name = "Corruption",
        description = "Skills cost 0. Whenever you play a Skill, Exhaust it.",
        -- Power effect is passive, checked in:
        -- - GetCost pipeline: Skills cost 0
        -- - PlayCard pipeline: Skills are exhausted
    }
}
