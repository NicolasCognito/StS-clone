local ContextValidators = require("Utils.ContextValidators")
-- TODO: This Searing Blow implementation is HORRIBLE; revisit when there's time.

local function updateDescription(self)
    self.description = string.format(
        "Deal %d damage. Can be Upgraded any number of times.",
        self.damage
    )
end

local function recalculateDamage(self)
    local upgrades = self.numberOfUpgrades or 0
    self.damage = self.baseDamage + (upgrades * self.damagePerUpgrade)
    updateDescription(self)
end

return {
    SearingBlow = {
        id = "SearingBlow",
        name = "Searing Blow",
        cost = 2,
        type = "ATTACK",
        character = "IRONCLAD",
        rarity = "UNCOMMON",
        baseDamage = 12,
        damage = 12,
        damagePerUpgrade = 4,
        allowMultipleUpgrades = true,
        trackUpgradeCount = true,
        description = "Deal 12 damage. Can be Upgraded any number of times.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })
        end,

        onUpgrade = function(self, upgradeCount)
            if upgradeCount then
                self.numberOfUpgrades = upgradeCount
            else
                self.numberOfUpgrades = (self.numberOfUpgrades or 0) + 1
            end

            recalculateDamage(self)
        end
    }
}
