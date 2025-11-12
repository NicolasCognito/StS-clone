-- START TURN PIPELINE
-- world: the complete game state
-- player: the player character
--
-- Handles:
-- - Clear turn-based player flags (cannotDraw from Bullet Time)
-- - Reset block to 0
-- - Draw cards (5 base + Snecko Eye bonus)
-- - Trigger any start-of-turn power effects
-- - Combat logging
--
-- This centralizes all turn-start logic in one place

local StartTurn = {}

local DrawCard = require("Pipelines.DrawCard")
local ChangeStance = require("Pipelines.ChangeStance")

function StartTurn.execute(world, player)
    table.insert(world.log, "--- Start of Player Turn ---")

    -- Exit Divinity stance if player is in it (Divinity only lasts one turn)
    if player.currentStance == "Divinity" then
        ChangeStance.execute(world, {newStance = nil})
    end

    -- Clear turn-based player flags
    player.cannotDraw = nil  -- Clear Bullet Time's "cannot draw" effect

    -- Reset turn-based duplication flags
    player.status = player.status or {}
    player.status.necronomiconThisTurn = false  -- Necronomicon can trigger again

    -- Set Echo Form counter from power stacks
    -- Echo Form: first N cards each turn are played twice (N = power stacks)
    if player.powers then
        local echoFormStacks = 0
        for _, power in ipairs(player.powers) do
            if power.id == "EchoForm" then
                echoFormStacks = echoFormStacks + power.stacks
            end
        end
        player.status.echoFormThisTurn = echoFormStacks
    end

    -- Plasma orbs: Gain 1 energy per Plasma orb at start of turn
    local plasmaCount = 0
    for _, orb in ipairs(player.orbs) do
        if orb.id == "Plasma" then
            plasmaCount = plasmaCount + 1
        end
    end
    if plasmaCount > 0 then
        player.energy = player.energy + plasmaCount
        table.insert(world.log, player.name .. " gained " .. plasmaCount .. " energy from " .. plasmaCount .. " Plasma orb(s)")
    end

    -- Reset block
    player.block = 0

    -- Calculate number of cards to draw
    local cardsToDraw = 5  -- Base draw

    -- Snecko Eye: Draw 2 additional cards
    if player.relics then
        for _, relic in ipairs(player.relics) do
            if relic.id == "Snecko_Eye" then
                cardsToDraw = cardsToDraw + 2
            end
        end
    end

    -- Draw cards
    DrawCard.execute(world, player, cardsToDraw)

    -- Enemies select their intents for the upcoming round
    -- This happens right after player gains energy
    if world.enemies then
        for _, enemy in ipairs(world.enemies) do
            if enemy.hp > 0 and enemy.selectIntent then
                enemy:selectIntent(world, player)
            end
        end
    end

    -- TODO: Trigger start-of-turn power effects here
    -- if player.powers then
    --     for _, power in ipairs(player.powers) do
    --         if power.onTurnStart then
    --             power:onTurnStart(world, player)
    --         end
    --     end
    -- end
end

return StartTurn
