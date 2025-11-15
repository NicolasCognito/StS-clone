return {
    Omniscience = {
        id = "Omniscience",
        name = "Omniscience",
        cost = 4,
        type = "SKILL",
        character = "COLORLESS",
        rarity = "RARE",
        exhausts = true,
        description = "Choose a card in your draw pile. Play it twice and Exhaust it.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "cards",
                    stability = "temp",
                    source = "combat",
                    count = {min = 1, max = 1},
                    filter = function(_, _, _, candidateCard)
                        return candidateCard.state == "DECK"
                    end
                }
            }, "FIRST")

            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    -- Lazy-load to avoid circular dependency
                    local PlayCard = require("Pipelines.PlayCard")
                    local ClearContext = require("Pipelines.ClearContext")

                    -- Read from indexed tempContext
                    local contextCards = world.combat.tempContext[self] or {}
                    local selection = contextCards[1]
                    if not selection then
                        table.insert(world.log, "Omniscience had no card to target.")
                        return
                    end

                    selection._previousState = selection.state
                    selection.state = "PROCESSING"
                    PlayCard.queueForcedReplay(selection, "Omniscience", 1)

                    local success = PlayCard.execute(world, player, selection, {
                        auto = true,
                        playSource = "Omniscience",
                        energySpentOverride = 0
                    })

                    if not success then
                        selection.state = selection._previousState or "DECK"
                        selection._previousState = nil
                        selection._forcedReplays = nil
                        table.insert(world.log, "Omniscience failed to resolve " .. selection.name .. ".")
                    else
                        if selection.state ~= "EXHAUSTED_PILE" then
                            world.queue:push({
                                type = "ON_EXHAUST",
                                card = selection,
                                source = "Omniscience"
                            })
                        end
                    end

                    -- No manual clearing needed with indexed tempContext
                end
            })
        end,

        onUpgrade = function(self)
            self.cost = 3
            self.description = "Choose a card in your draw pile. Play it twice and Exhaust it."
        end
    }
}
