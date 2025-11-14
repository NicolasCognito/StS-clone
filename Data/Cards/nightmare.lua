local ContextValidators = require("Utils.ContextValidators")

return {
    Nightmare = {
        id = "Nightmare",
        name = "Nightmare",
        cost = 3,
        type = "SKILL",
        character = "SILENT",
        rarity = "RARE",
        exhausts = true,
        description = "Choose a card. Next turn, add 3 copies of it to your hand.",

        onPlay = function(self, world, player)
            -- Request card selection (stable context - same card for duplications)
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "cards",
                    stability = "stable",
                    source = "combat",
                    count = {min = 1, max = 1},
                    filter = function(_, _, _, candidate)
                        return candidate.state == "HAND" and candidate ~= self
                    end
                }
            }, "FIRST")

            -- Create 3 copies with NIGHTMARE state using AcquireCard pipeline
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local selectedCard = world.combat.stableContext
                    if not selectedCard then
                        table.insert(world.log, "Nightmare: No card selected")
                        return
                    end

                    local AcquireCard = require("Pipelines.AcquireCard")

                    -- Use new AcquireCard pipeline with NIGHTMARE state
                    AcquireCard.execute(world, player, selectedCard, {
                        destination = "NIGHTMARE",
                        count = 3
                    })

                    table.insert(world.log, "Nightmare: 3 copies of " .. selectedCard.name .. " will arrive next turn")
                end
            })
        end,

        onUpgrade = function(self)
            self.cost = 2
            self.description = "Choose a card. Next turn, add 3 copies of it to your hand."
        end
    }
}
