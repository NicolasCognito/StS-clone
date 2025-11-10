return {
    EchoForm = {
        id = "EchoForm",
        name = "Echo Form",
        stacks = 1,
        description = "The first card you play each turn is played twice.",
        -- Power effect is passive, handled in:
        -- - StartTurn pipeline: Sets player.status.echoFormThisTurn based on stacks
        -- - PlayCard pipeline: Checks echoFormThisTurn counter for duplication
        -- Multiple stacks mean the first N cards each turn are duplicated
    }
}
