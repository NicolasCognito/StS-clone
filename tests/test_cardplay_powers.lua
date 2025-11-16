-- TEST: Card-play reactive powers (Panache, A Thousand Cuts, After Image)

local World = require("World")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")
local Utils = require("utils")

local function playCard(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            return true
        end

        if type(result) == "table" and result.needsContext then
            local request = world.combat.contextRequest
            local context = ContextProvider.execute(world, player, request.contextProvider, request.card)

            if request.stability == "stable" then
                world.combat.stableContext = context
            else
                world.combat.tempContext = context
            end
            world.combat.contextRequest = nil
        end
    end
end

print("=== Testing Panache + A Thousand Cuts + After Image ===\n")

local world = World.createWorld({
    playerName = "Tester",
    playerClass = "SILENT",
    maxEnergy = 10
})

local panache = Utils.deepCopyCard(Cards.Panache)
panache.state = "HAND"

local afterImage = Utils.deepCopyCard(Cards.AfterImage)
afterImage.state = "HAND"

local thousandCuts = Utils.deepCopyCard(Cards.AThousandCuts)
thousandCuts.state = "HAND"

local strikes = {}
for i = 1, 5 do
    local strike = Utils.deepCopyCard(Cards.Strike)
    strike.state = "HAND"
    table.insert(strikes, strike)
end

world.player.masterDeck = {panache, afterImage, thousandCuts}
for _, strike in ipairs(strikes) do
    table.insert(world.player.masterDeck, strike)
end
world.player.combatDeck = Utils.deepCopyDeck(world.player.masterDeck)

world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
world.enemies[1].hp = 100
world.enemies[1].maxHp = 100

StartCombat.execute(world)

playCard(world, world.player, panache)
assert(Utils.hasPower(world.player, "Panache"), "Panache status missing")
assert(world.player.status.panache == 10, "Panache damage should be 10")

playCard(world, world.player, afterImage)
assert(world.player.status.after_image == 1, "After Image stacks should be 1")

playCard(world, world.player, thousandCuts)
assert(world.player.status.a_thousand_cuts == 1, "A Thousand Cuts stacks should be 1")

-- After Image should have granted block for itself and Thousand Cuts
assert(world.player.block == 2, "Block should be 2 after playing After Image and A Thousand Cuts")

-- Play 5 Strikes to trigger card-play hooks
for _, strike in ipairs(strikes) do
    playCard(world, world.player, strike)
end

-- Total cards that benefited from After Image: After Image itself, A Thousand Cuts, and 5 Strikes = 7
assert(world.player.block == 7, "After Image should have granted 7 total Block (got " .. world.player.block .. ")")

-- Damage accounting: 5 Strikes (30) + A Thousand Cuts from 6 cards (6) + Panache trigger (10) = 46
local expectedHp = 100 - 46
assert(world.enemies[1].hp == expectedHp, "Enemy HP should be " .. expectedHp .. " (got " .. world.enemies[1].hp .. ")")

print("✓ Combined power hooks verified successfully\n")
