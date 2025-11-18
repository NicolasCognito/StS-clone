-- AWAKENED ONE BOSS
-- Act 3 boss that punishes Power cards with Curiosity in Phase 1
-- When defeated in Phase 1, uses Rebirth to restore HP and transform to Phase 2

return {
    AwakenedOne = {
        id = "AwakenedOne",
        name = "Awakened One",
        hp = 300,  -- 320 on Ascension 9+
        maxHp = 300,
        block = 0,
        damage = 20,  -- Base damage for Slash
        description = "Act 3 boss. Punishes Power cards in Phase 1, then transforms.",

        -- Phase tracking (1 = Unawakened, 2 = Awakened)
        phase = 1,

        -- Rebirth flag - can only rebirth once
        canRebirth = true,

        -- Intent functions
        intents = {
            -- PHASE 1 ATTACKS
            slash = function(self, world, player)
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = {damage = 20, strengthMultiplier = 1}
                })
            end,

            soulStrike = function(self, world, player)
                -- Multi-hit attack (4 hits of 6 damage)
                for i = 1, 4 do
                    world.queue:push({
                        type = "ON_ATTACK_DAMAGE",
                        attacker = self,
                        defender = player,
                        card = {damage = 6, strengthMultiplier = 1}
                    })
                end
            end,

            -- PHASE 2 ATTACKS
            darkEcho = function(self, world, player)
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = {damage = 40, strengthMultiplier = 1}
                })
            end,

            tackle = function(self, world, player)
                -- Multi-hit attack (3 hits of 10 damage)
                for i = 1, 3 do
                    world.queue:push({
                        type = "ON_ATTACK_DAMAGE",
                        attacker = self,
                        defender = player,
                        card = {damage = 10, strengthMultiplier = 1}
                    })
                end
            end,

            sludge = function(self, world, player)
                -- Deal damage
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = {damage = 18, strengthMultiplier = 1}
                })

                -- Shuffle 1 Void into player's draw pile
                local Cards = require("Data.cards")
                local AcquireCard = require("Pipelines.AcquireCard")

                if Cards.Void then
                    AcquireCard.execute(world, player, Cards.Void, {
                        destination = "DECK",  -- Draw pile
                        targetDeck = "combat"
                    })
                    table.insert(world.log, "Sludge: 1 Void shuffled into draw pile")
                end
            end,

            -- REBIRTH (transformation)
            rebirth = function(self, world, player)
                -- Restore to full HP
                self.hp = self.maxHp

                -- Remove Curiosity
                if self.status and self.status.curiosity then
                    self.status.curiosity = nil
                    table.insert(world.log, self.name .. " loses Curiosity")
                end

                -- Transform to Phase 2
                self.phase = 2
                self.name = "Awakened One (Phase 2)"

                -- Mark rebirth as used
                self.canRebirth = false

                -- Reset intent history for fresh Phase 2 AI
                self.intentHistory = {}

                table.insert(world.log, self.name .. " has awakened! HP restored to " .. self.hp .. "/" .. self.maxHp)
            end
        },

        -- AI selector function
        selectIntent = function(self, world, player)
            -- Initialize intent history if needed
            if not self.intentHistory then
                self.intentHistory = {}
            end

            local lastMove = self.intentHistory[#self.intentHistory]
            local secondLastMove = #self.intentHistory >= 2 and self.intentHistory[#self.intentHistory - 1] or nil

            if self.phase == 1 then
                -- PHASE 1: Slash (75%) or Soul Strike (25%)
                local validMoves = {}

                -- Slash cannot be used 3 times in a row
                if not (lastMove == "Slash" and secondLastMove == "Slash") then
                    validMoves.slash = 75
                end

                -- Soul Strike cannot be used twice in a row
                if lastMove ~= "Soul Strike" then
                    validMoves.soulStrike = 25
                end

                -- Select move based on probability
                local totalWeight = 0
                for _, weight in pairs(validMoves) do
                    totalWeight = totalWeight + weight
                end

                local roll = math.random() * totalWeight
                local cumulative = 0

                for move, weight in pairs(validMoves) do
                    cumulative = cumulative + weight
                    if roll <= cumulative then
                        if move == "slash" then
                            self.currentIntent = {
                                name = "Slash",
                                description = "Deal 20 damage",
                                intentType = "ATTACK",
                                execute = self.intents.slash
                            }
                        elseif move == "soulStrike" then
                            self.currentIntent = {
                                name = "Soul Strike",
                                description = "Deal 6 damage 4 times",
                                intentType = "ATTACK",
                                execute = self.intents.soulStrike
                            }
                        end
                        return
                    end
                end

                -- Fallback
                self.currentIntent = {
                    name = "Slash",
                    description = "Deal 20 damage",
                    intentType = "ATTACK",
                    execute = self.intents.slash
                }

            else
                -- PHASE 2: Dark Echo first, then Tackle (50%) / Sludge (50%)
                if #self.intentHistory == 0 then
                    -- First move in Phase 2 is always Dark Echo
                    self.currentIntent = {
                        name = "Dark Echo",
                        description = "Deal 40 damage",
                        intentType = "ATTACK",
                        execute = self.intents.darkEcho
                    }
                    return
                end

                local validMoves = {}

                -- Tackle cannot be used 3 times in a row
                if not (lastMove == "Tackle" and secondLastMove == "Tackle") then
                    validMoves.tackle = 50
                end

                -- Sludge cannot be used 3 times in a row
                if not (lastMove == "Sludge" and secondLastMove == "Sludge") then
                    validMoves.sludge = 50
                end

                -- Select move
                local totalWeight = 0
                for _, weight in pairs(validMoves) do
                    totalWeight = totalWeight + weight
                end

                local roll = math.random() * totalWeight
                local cumulative = 0

                for move, weight in pairs(validMoves) do
                    cumulative = cumulative + weight
                    if roll <= cumulative then
                        if move == "tackle" then
                            self.currentIntent = {
                                name = "Tackle",
                                description = "Deal 10 damage 3 times",
                                intentType = "ATTACK",
                                execute = self.intents.tackle
                            }
                        elseif move == "sludge" then
                            self.currentIntent = {
                                name = "Sludge",
                                description = "Deal 18 damage. Shuffle 1 Void into draw pile.",
                                intentType = "ATTACK",
                                execute = self.intents.sludge
                            }
                        end
                        return
                    end
                end

                -- Fallback
                self.currentIntent = {
                    name = "Tackle",
                    description = "Deal 10 damage 3 times",
                    intentType = "ATTACK",
                    execute = self.intents.tackle
                }
            end
        end,

        executeIntent = function(self, world, player)
            if self.currentIntent and self.currentIntent.execute then
                self.currentIntent.execute(self, world, player)
            end
        end
    }
}
