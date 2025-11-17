return {
    TimeEater = {
        id = "TimeEater",
        name = "Time Eater",
        hp = 456,
        maxHp = 456,
        block = 0,
        description = "Time Eater punishes decks that play many cards. Time Warp ends your turn after 12 cards.",

        -- Intent functions
        intents = {
            reverberate = function(self, world, player)
                -- Deal 7 damage 3 times
                for i = 1, 3 do
                    world.queue:push({
                        type = "ON_ATTACK_DAMAGE",
                        attacker = self,
                        defender = player,
                        card = {damage = 7, strengthMultiplier = 1}
                    })
                end
            end,

            head_slam = function(self, world, player)
                -- Deal 26 damage + apply 1 Draw Reduction
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = {damage = 26, strengthMultiplier = 1}
                })

                -- Apply Draw Reduction
                world.queue:push({
                    type = "ON_STATUS_GAIN",
                    target = player,
                    effectType = "draw_reduction",
                    amount = 1,
                    source = "Head Slam"
                })
            end,

            ripple = function(self, world, player)
                -- Gain 20 Block
                world.queue:push({
                    type = "ON_BLOCK",
                    target = self,
                    amount = 20,
                    source = "Ripple"
                })

                -- Apply 1 Vulnerable
                world.queue:push({
                    type = "ON_STATUS_GAIN",
                    target = player,
                    effectType = "vulnerable",
                    amount = 1,
                    source = "Ripple"
                })

                -- Apply 1 Weak
                world.queue:push({
                    type = "ON_STATUS_GAIN",
                    target = player,
                    effectType = "weak",
                    amount = 1,
                    source = "Ripple"
                })
            end,

            haste = function(self, world, player)
                -- Heal to 50% HP
                local targetHp = math.floor(self.maxHp / 2)
                local healAmount = targetHp - self.hp

                if healAmount > 0 then
                    self.hp = targetHp
                    table.insert(world.log, self.name .. " used Haste! Healed to " .. targetHp .. " HP")
                end

                -- Remove all debuffs
                if self.status then
                    local debuffTypes = {"vulnerable", "weak", "frail", "poison", "mark", "constricted", "choked", "draw_reduction", "entangled", "hex", "no_block", "no_draw", "bias"}

                    for _, debuffType in ipairs(debuffTypes) do
                        if self.status[debuffType] and self.status[debuffType] > 0 then
                            self.status[debuffType] = 0
                        end
                    end

                    -- Remove negative strength/dexterity
                    if self.status.strength and self.status.strength < 0 then
                        self.status.strength = 0
                    end
                    if self.status.dexterity and self.status.dexterity < 0 then
                        self.status.dexterity = 0
                    end

                    table.insert(world.log, self.name .. " removed all debuffs!")
                end
            end
        },

        -- Selector function: Choose next intent
        selectIntent = function(self, world, player)
            -- Initialize on first call
            if not self.initialized then
                self.initialized = true
                self.status = self.status or {}

                -- Start with Time Warp at 12
                self.status.time_warp = 12
                table.insert(world.log, "Time Eater starts with Time Warp (12)")

                self.hasteUsed = false
            end

            -- Check for Haste trigger (once when HP drops below 50%)
            if not self.hasteUsed and self.hp < (self.maxHp / 2) then
                self.hasteUsed = true
                self.currentIntent = {
                    name = "Haste",
                    description = "Heal to 50% HP. Remove all debuffs.",
                    intentType = "BUFF",
                    execute = self.intents.haste
                }
                return
            end

            -- Select attack move with weighted probabilities
            -- Reverberate: 45%, Head Slam: 35%, Ripple: 20%
            -- Restrictions:
            --   - Ripple cannot be used twice in a row
            --   - Head Slam cannot be used twice in a row
            --   - Reverberate cannot be used three times in a row

            -- Read from intentHistory (populated automatically by EnemyTakeTurn)
            local lastMove = self.intentHistory and self.intentHistory[#self.intentHistory]
            local secondLastMove = self.intentHistory and self.intentHistory[#self.intentHistory - 1]

            local validMoves = {}

            -- Check Reverberate (45% weight)
            -- Cannot use if last 2 moves were Reverberate
            if not (lastMove == "Reverberate" and secondLastMove == "Reverberate") then
                table.insert(validMoves, {name = "reverberate", weight = 45})
            end

            -- Check Head Slam (35% weight)
            -- Cannot use if last move was Head Slam
            if lastMove ~= "Head Slam" then
                table.insert(validMoves, {name = "head_slam", weight = 35})
            end

            -- Check Ripple (20% weight)
            -- Cannot use if last move was Ripple
            if lastMove ~= "Ripple" then
                table.insert(validMoves, {name = "ripple", weight = 20})
            end

            -- Weighted random selection
            local totalWeight = 0
            for _, move in ipairs(validMoves) do
                totalWeight = totalWeight + move.weight
            end

            local roll = math.random() * totalWeight
            local selectedMove = "reverberate" -- fallback

            local cumulative = 0
            for _, move in ipairs(validMoves) do
                cumulative = cumulative + move.weight
                if roll <= cumulative then
                    selectedMove = move.name
                    break
                end
            end

            -- Set intent based on selected move
            -- Note: intentHistory is populated automatically by EnemyTakeTurn pipeline
            if selectedMove == "reverberate" then
                self.currentIntent = {
                    name = "Reverberate",
                    description = "Deal 21 damage (7×3)",
                    intentType = "ATTACK",
                    execute = self.intents.reverberate
                }
            elseif selectedMove == "head_slam" then
                self.currentIntent = {
                    name = "Head Slam",
                    description = "Deal 26 damage. Apply 1 Draw Reduction.",
                    intentType = "ATTACK",
                    execute = self.intents.head_slam
                }
            else -- ripple
                self.currentIntent = {
                    name = "Ripple",
                    description = "Gain 20 Block. Apply 1 Vulnerable and 1 Weak.",
                    intentType = "DEFEND_DEBUFF",
                    execute = self.intents.ripple
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
