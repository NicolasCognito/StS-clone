return {
    GeneticAlgorithm = {
        id = "GeneticAlgorithm",
        name = "Genetic Algorithm",
        cost = 1,
        type = "SKILL",
        character = "DEFECT",
        rarity = "UNCOMMON",
        block = 1,
        blockIncrease = 2,  -- Per-play bonus (changes to 3 when upgraded)
        exhausts = true,
        description = "Gain 1 Block. Permanently increase this card's Block by 2. Exhaust.",

        onPlay = function(self, world, player)
            -- Gain block first
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                card = self,
                source = self
            })

            -- Permanently increase block on this card
            self.block = self.block + self.blockIncrease

            -- Find and update the masterDeck version to persist the change
            for _, deckCard in ipairs(world.player.masterDeck) do
                if deckCard.id == "GeneticAlgorithm" then
                    deckCard.block = self.block
                    break  -- Only update first match
                end
            end

            -- Update description dynamically
            local increaseText = self.upgraded and "3" or "2"
            self.description = "Gain " .. self.block .. " Block. Permanently increase this card's Block by " .. increaseText .. ". Exhaust."

            table.insert(world.log, "Genetic Algorithm's block increased to " .. self.block .. "!")
        end,

        onUpgrade = function(self)
            self.blockIncrease = 3
            local currentBlock = self.block or 1
            self.description = "Gain " .. currentBlock .. " Block. Permanently increase this card's Block by 3. Exhaust."
        end
    }
}
