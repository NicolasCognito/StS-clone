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

            -- Create 3 copies with NIGHTMARE state
            -- NOTE: This bypasses the AcquireCard pipeline intentionally.
            -- Nightmare creates copies directly with special NIGHTMARE state,
            -- which are moved to hand by StartTurn.lua next turn.
            -- This avoids triggering card acquisition hooks (relics, etc.)
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local selectedCard = world.combat.stableContext
                    if not selectedCard then
                        table.insert(world.log, "Nightmare: No card selected")
                        return
                    end

                    local Utils = require("utils")

                    -- Create 3 copies with NIGHTMARE state
                    for i = 1, 3 do
                        local copy = Utils.deepCopyCard(selectedCard)

                        -- Check for Master Reality power: auto-upgrade created cards
                        if Utils.hasPower(player, "MasterReality") then
                            if not copy.upgraded and type(copy.onUpgrade) == "function" then
                                copy:onUpgrade()
                                copy.upgraded = true
                            end
                        end

                        copy.state = "NIGHTMARE"  -- Special state for next turn
                        table.insert(player.combatDeck, copy)
                    end

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
