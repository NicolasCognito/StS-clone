-- Test: Medkit Relic
-- Tests that Status cards can be played with Medkit relic
-- NOTE: Status cards are not yet implemented in the codebase
-- This test serves as a template for when Status cards are added

local World = require("World")
local Utils = require("utils")
local Relics = require("Data.relics")

print("=== Medkit Relic Tests ===\n")

-- TEST 1: Medkit relic exists and can be acquired
print("Test 1: Medkit relic exists")
do
    assert(Relics.Medkit ~= nil, "Medkit relic should exist")
    assert(Relics.Medkit.id == "Medkit", "Medkit should have correct id")
    assert(Relics.Medkit.name == "Medkit", "Medkit should have correct name")
    assert(Relics.Medkit.rarity == "SHOP", "Medkit should be a Shop relic")

    print("✓ Medkit relic exists with correct properties")
end

-- TEST 2: Medkit can be given to player
print("Test 2: Medkit can be given to player")
do
    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        relics = {Relics.Medkit}
    })

    assert(Utils.hasRelic(world.player, "Medkit"), "Player should have Medkit relic")

    print("✓ Medkit can be given to player")
end

print("\n=== Medkit relic tests passed! ===")
print("\nNOTE: Full Medkit functionality tests require Status cards to be implemented.")
print("When Status cards (Dazed, Void, Wound, Burn) are added, implement tests similar to test_bluecandle.lua:")
print("  - Status cards should be unplayable WITHOUT Medkit")
print("  - Status cards should be playable WITH Medkit")
print("  - Status cards should cost 0 energy")
print("  - Status cards should exhaust when played")
