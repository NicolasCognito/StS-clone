-- NOTE: A Thousand Cuts' per-card damage trigger is implemented in Pipelines/AfterCardPlayed.lua

return {
    AThousandCuts = {
        id = "AThousandCuts",
        name = "A Thousand Cuts",
        cost = 2,
        type = "POWER",
        character = "SILENT",
        rarity = "RARE",
        damagePerCard = 1,
        description = "Whenever you play a card, deal 1 damage to ALL enemies.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "a_thousand_cuts",
                amount = self.damagePerCard,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.damagePerCard = 2
            self.description = "Whenever you play a card, deal 2 damage to ALL enemies."
        end
    }
}
