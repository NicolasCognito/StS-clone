local World = require("World")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")
local DrawCard = require("Pipelines.DrawCard")
local EndTurn = require("Pipelines.EndTurn")
local StartTurn = require("Pipelines.StartTurn")
local GetCost = require("Pipelines.GetCost")
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

print("=== Testing Bullet Time ===\n")

local world = World.createWorld({
    playerName = "Tester",
    playerClass = "SILENT",
    maxEnergy = 10
})

world.NoShuffle = true

local bulletTime = Utils.deepCopyCard(Cards.BulletTime)
local strike = Utils.deepCopyCard(Cards.Strike)
strike.debugLabel = "Strike1"
local extraCards = {}
for i = 1, 4 do
    local filler = Utils.deepCopyCard(Cards.Defend)
    filler.debugLabel = "Defend" .. i
    table.insert(extraCards, filler)
end

world.player.masterDeck = {bulletTime, strike}
for _, card in ipairs(extraCards) do
    table.insert(world.player.masterDeck, card)
end

world.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}

StartCombat.execute(world)

local bulletCard
local strikeCard
for _, card in ipairs(world.player.combatDeck) do
    if card.id == "BulletTime" then
        bulletCard = card
    elseif card.debugLabel == "Strike1" then
        strikeCard = card
    end
end

assert(bulletCard, "Bullet Time card not found")
assert(strikeCard, "Strike card not found")

-- Ensure both cards are in hand for the test
bulletCard.state = "HAND"
strikeCard.state = "HAND"

playCard(world, world.player, bulletCard)

assert(world.player.status.no_draw == 1, "Player should have No Draw status after Bullet Time")
assert(strikeCard.costsZeroThisTurn == 1, "Strike should cost 0 this turn")
assert(GetCost.execute(world, world.player, strikeCard) == 0, "Strike cost should be 0 during Bullet Time turn")

local handBefore = #Utils.getCardsByState(world.player.combatDeck, "HAND")
DrawCard.execute(world, world.player, 1)
local handAfter = #Utils.getCardsByState(world.player.combatDeck, "HAND")
assert(handBefore == handAfter, "Hand size should not change while No Draw is active")

EndTurn.execute(world, world.player)
assert(world.player.status.no_draw == nil, "No Draw should clear at end of turn")

StartTurn.execute(world, world.player)
assert(strikeCard.costsZeroThisTurn == nil, "Temporary cost reduction should expire at end of turn")
assert(GetCost.execute(world, world.player, strikeCard) == strikeCard.cost, "Strike cost should return to base value")

print("✓ Bullet Time behavior verified\n")
