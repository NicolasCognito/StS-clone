-- TEST: Verify that newly spawned slimes don't attack in the same round they're spawned

local World = require("World")
local Utils = require("utils")
local Enemies = require("Data.enemies")
local Cards = require("Data.cards")
local StartCombat = require("Pipelines.StartCombat")
local EnemyTakeTurn = require("Pipelines.EnemyTakeTurn")

math.randomseed(1337)

print("=== TEST: Slime spawn attack behavior ===")

-- Create a simple test
local world = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    currentHp = 80,
    maxEnergy = 6,
    cards = {Utils.copyCardTemplate(Cards.Strike)},
    relics = {}
})

-- Create a Slime Boss
world.enemies = {Utils.copyEnemyTemplate(Enemies.SlimeBoss)}
world.NoShuffle = true
StartCombat.execute(world)

local boss = world.enemies[1]
local player = world.player

-- Record initial HP
local initialPlayerHp = player.hp

-- Force boss to split
boss.currentIntent = {
    name = "Split",
    description = "Split into 2 slimes",
    execute = boss.intents.split
}

-- Count enemies before split
local enemiesBeforeSplit = #world.enemies
print("Enemies before split: " .. enemiesBeforeSplit)

-- Execute boss turn (this will split)
EnemyTakeTurn.execute(world, boss, player)

-- Count enemies after split
local enemiesAfterSplit = #world.enemies
print("Enemies after split: " .. enemiesAfterSplit)

-- Check if any slimes have intents set
for i, enemy in ipairs(world.enemies) do
    print("Enemy " .. i .. " (" .. enemy.name .. "):")
    print("  HP: " .. enemy.hp)
    print("  Has currentIntent: " .. tostring(enemy.currentIntent ~= nil))
    if enemy.currentIntent then
        print("  Intent name: " .. (enemy.currentIntent.name or "nil"))
    end
end

-- Check player HP (did slimes attack?)
print("\nPlayer HP before split: " .. initialPlayerHp)
print("Player HP after split: " .. player.hp)

if player.hp < initialPlayerHp then
    print("❌ PROBLEM: Player took damage from newly spawned slimes!")
    print("   Slimes attacked in the same round they were spawned.")
else
    print("✓ Player HP unchanged - slimes did not attack in spawn round")
end

print("\n=== Testing ipairs behavior during table modification ===")
-- Test how ipairs handles table modification during iteration
local testTable = {"A", "B", "C"}
print("Original table: " .. table.concat(testTable, ", "))

local visitedOrder = {}
for i, v in ipairs(testTable) do
    table.insert(visitedOrder, v)
    print("Visiting index " .. i .. ": " .. v)

    if v == "B" then
        -- Simulate boss splitting: remove self, add 2 new
        print("  -> Removing 'B' and adding 'D', 'E'")
        table.remove(testTable, i)  -- Remove current
        table.insert(testTable, "D")  -- Add new
        table.insert(testTable, "E")  -- Add new
        print("  -> Table is now: " .. table.concat(testTable, ", "))
    end
end

print("Visited in order: " .. table.concat(visitedOrder, ", "))
print("Final table: " .. table.concat(testTable, ", "))

print("\n=== Test Complete ===")
