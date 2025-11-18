return {
    ChampionsBelt = {
        id = "Champions_Belt",
        name = "Champion's Belt",
        rarity = "RARE",
        character = "IRONCLAD",
        description = "Whenever you apply Vulnerable, also apply 1 Weak.",

        onStatusGain = function(self, world, player, eventData)
            -- Only trigger if Vulnerable was applied with positive amount
            if eventData.effectType == "Vulnerable" and eventData.amount > 0 then
                -- Only apply to enemies (not the player)
                if eventData.target ~= player then
                    world.queue:push({
                        type = "ON_STATUS_GAIN",
                        target = eventData.target,
                        effectType = "Weak",
                        amount = 1,
                        source = self
                    })
                end
            end
        end
    }
}
