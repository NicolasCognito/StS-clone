local Utils = require("utils")
local Cards = require("Data.cards")
local UpgradeCard = require("Pipelines.UpgradeCard")

print("=== Test: Searing Blow infinite upgrades ===")

do
    local card = Utils.copyCardTemplate(Cards.SearingBlow)

    assert(card.damage == 12, "Base damage should start at 12")
    assert(UpgradeCard.canUpgrade(card), "Searing Blow should be upgradeable")

    for i = 1, 4 do
        local success = UpgradeCard.execute(nil, card)
        assert(success, "Upgrade #" .. i .. " should succeed")
        local expectedDamage = 12 + (4 * i)
        assert(card.damage == expectedDamage, "Damage should be " .. expectedDamage .. " after upgrade " .. i)
        assert(card.numberOfUpgrades == i, "Upgrade counter should be " .. i)
        assert(UpgradeCard.canUpgrade(card), "Searing Blow should always be upgradeable")
    end

    print("✓ Searing Blow scales damage with unlimited upgrades")
end

