return {
    BulletTime = {
        id = "BulletTime",
        name = "Bullet Time",
        cost = 3,
        type = "SKILL",
        character = "SILENT",
        rarity = "RARE",
        description = "You cannot draw additional cards this turn. Reduce the cost of all cards in your hand to 0 this turn.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "no_draw",
                amount = 1,
                source = self
            })

            local setCount = 0
            for _, card in ipairs(player.combatDeck) do
                if card.state == "HAND" then
                    card.costsZeroThisTurn = 1
                    setCount = setCount + 1
                end
            end

            table.insert(world.log, "Bullet Time sets " .. setCount .. " hand card(s) to 0 cost this turn")
        end,

        onUpgrade = function(self)
            self.cost = 2
            self.description = "You cannot draw additional cards this turn. Reduce the cost of all cards in your hand to 0 this turn."
            self.upgraded = true
        end
    }
}
