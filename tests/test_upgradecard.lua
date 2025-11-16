local UpgradeCard = require("Pipelines.UpgradeCard")

local function createWorld()
    return {
        log = {}
    }
end

print("=== Test 1: Standard card upgrades only once ===")
do
    local world = createWorld()
    local card = {
        id = "TestStrike",
        name = "Test Strike",
        damage = 6,
        onUpgrade = function(self)
            self.damage = self.damage + 2
        end
    }

    assert(UpgradeCard.canUpgrade(card), "Card should be upgradeable initially")
    assert(UpgradeCard.execute(world, card), "Upgrade should succeed")
    assert(card.upgraded == true, "Card should be marked upgraded")
    assert(card.damage == 8, "Damage should increase after upgrade")
    assert(not UpgradeCard.canUpgrade(card), "Card should not be upgradeable twice")

    print("✓ Standard card only upgrades once")
end

print("\n=== Test 2: Unlimited upgrade card increments each time ===")
do
    local world = createWorld()
    local card = {
        id = "SearingBlow",
        name = "Searing Blow",
        baseDamage = 12,
        damage = 12,
        trackUpgradeCount = true,
        onUpgrade = function(self, upgradeCount)
            self.damage = self.baseDamage + (upgradeCount * 4)
        end
    }

    -- Should be upgradeable indefinitely
    for i = 1, 3 do
        assert(UpgradeCard.execute(world, card), "Upgrade #" .. i .. " should succeed")
        assert(card.numberOfUpgrades == i, "Upgrade count should be " .. i)
        local expected = 12 + i * 4
        assert(card.damage == expected, "Damage should be " .. expected .. " after upgrade " .. i)
    end

    print("✓ Unlimited upgrade card can be upgraded multiple times")
end

print("\n=== Test 3: canUpgrade respects missing onUpgrade ===")
do
    local card = {id = "Noop"}
    assert(UpgradeCard.canUpgrade(card) == false, "Card without onUpgrade should not be upgradeable")
    print("✓ Cards without onUpgrade are ignored")
end
