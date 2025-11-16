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
                            and candidateCard.type ~= "STATUS"
                            and candidateCard.type ~= "CURSE"
                            and type(candidateCard.onPlay) == "function"
                    end
                }
            }, "FIRST")

            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    -- Lazy-load to avoid circular dependency
                    local PlayCard = require("Pipelines.PlayCard")
                    local ClearContext = require("Pipelines.ClearContext")

                    local selection = world.combat.tempContext and world.combat.tempContext[1]
                    if not selection then
                        table.insert(world.log, "Omniscience had no card to target.")
                        return
                    end

                    selection._previousState = selection.state
                    selection.state = "PROCESSING"
                    PlayCard.queueForcedReplay(selection, "Omniscience", 1)

                    -- OLD IMPLEMENTATION (before forcedExhaust pattern):
                    -- Played card without forcedExhaust option, then manually checked if card
                    -- was already exhausted and queued exhaust event if needed:
                    --
                    -- local success = PlayCard.execute(world, player, selection, {
                    --     auto = true,
                    --     playSource = "Omniscience",
                    --     energySpentOverride = 0
                    -- })
                    --
                    -- if not success then
                    --     selection.state = selection._previousState or "DECK"
                    --     selection._previousState = nil
                    --     selection._forcedReplays = nil
                    --     table.insert(world.log, "Omniscience failed to resolve " .. selection.name .. ".")
                    -- else
                    --     if selection.state ~= "EXHAUSTED_PILE" then
                    --         world.queue:push({
                    --             type = "ON_EXHAUST",
                    --             card = selection,
                    --             source = "Omniscience"
                    --         })
                    --     end
                    -- end

                    -- NEW IMPLEMENTATION (using forcedExhaust pattern like Havoc):
                    -- This is cleaner and consistent with Havoc's approach
                    --
                    -- NOTE: Card text says "Play it twice, THEN exhaust" which implies the card
                    -- should be exhausted after all duplications complete. However, the current
                    -- forcedExhaust implementation exhausts after each individual play (including
                    -- shadow copies). This works correctly because:
                    -- 1. The first play moves card to EXHAUSTED_PILE
                    -- 2. Shadow copies don't change the original card's state
                    -- 3. End result is the same: card ends up exhausted after all plays
                    -- This is a technical implementation detail that doesn't affect gameplay.
                    local success = PlayCard.execute(world, player, selection, {
                        auto = true,
                        playSource = "Omniscience",
                        energySpentOverride = 0,
                        forcedExhaust = "Omniscience"  -- Force card to exhaust after play
                    })

                    if not success then
                        selection.state = selection._previousState or "DECK"
                        selection._previousState = nil
                        selection._forcedReplays = nil
                        table.insert(world.log, "Omniscience failed to resolve " .. selection.name .. ".")
                    end

                    ClearContext.execute(world, {clearTemp = true, clearStable = false})
                end
            })
        end,

        onUpgrade = function(self)
            self.cost = 3
            self.description = "Choose a card in your draw pile. Play it twice and Exhaust it."
        end
    }
}
