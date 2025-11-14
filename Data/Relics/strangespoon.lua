return {
    Strange_Spoon = {
        id = "Strange_Spoon",
        name = "Strange Spoon",
        tier = "shop",
        description = "Cards that Exhaust have a 50% chance to be sent to your discard pile instead.",

        -- NOTE: The actual logic is implemented in:
        -- - PlayCard.lua: Sets affectedBySpoon tag with 50% chance
        -- - Exhaust.lua: Checks tag and sends to discard instead
    }
}
