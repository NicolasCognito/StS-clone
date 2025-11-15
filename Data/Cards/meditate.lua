return {
    Meditate = {
        id = "Meditate",
        name = "Meditate",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "Choose 1 card from your discard pile. Place it into your hand and it Retains. Enter Calm. End your turn.",
        cardCount = 1,

        onPlay = function(self, world, player)
            -- Request card selection from discard pile
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "cards",
                    stability = "temp",
                    source = "combat",
                    count = {min = self.cardCount, max = self.cardCount},
                    filter = function(_, _, _, candidateCard)
                        return candidateCard.state == "DISCARD_PILE"
                    end
                }
            }, "FIRST")

            -- Pull selected cards to hand and make them Retain
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local selectedCards = world.combat.tempContext or {}

                    for _, card in ipairs(selectedCards) do
                        card.state = "HAND"
                        card.retain = true
                        table.insert(world.log, card.name .. " was placed into hand and will Retain")
                    end

                    -- Clear tempContext after using it (manual cleanup)
                    world.combat.tempContext = nil
                end
            })

            -- Enter Calm stance
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = "Calm"
            })

            -- End turn (set a flag that CombatEngine will check)
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    world.combat.meditateEndTurn = true
                end
            })
        end,

        onUpgrade = function(self)
            self.cardCount = 2
            self.description = "Choose 2 cards from your discard pile. Place them into your hand and they Retain. Enter Calm. End your turn."
            self.upgraded = true
        end
    }
}
