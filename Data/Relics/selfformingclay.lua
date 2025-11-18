return {
    SelfFormingClay = {
        id = "Self_Forming_Clay",
        name = "Self-Forming Clay",
        rarity = "UNCOMMON",
        character = "IRONCLAD",
        description = "Whenever you lose HP in combat, gain 3 Block next turn.",
        blockAmount = 3,

        onDmg = function(self, world, player, eventData)
            -- Only trigger if player lost HP (damage > 0 after block)
            if eventData.target == player and eventData.damage > 0 then
                world.queue:push({
                    type = "ON_STATUS_GAIN",
                    target = player,
                    effectType = "next_turn_block",
                    amount = self.blockAmount
                })
            end
        end
    }
}
