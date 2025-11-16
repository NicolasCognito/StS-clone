-- BEFORE CARD PLAYED PIPELINE
-- Called BEFORE a card's onPlay effect executes
-- Handles all pre-execution triggers and bookkeeping
--
-- Triggers:
-- - Statistics tracking (Powers played count)
-- - Storm power (channel Lightning when playing Powers)
-- - Pen Nib counter increment (for Attacks)
-- - Pain curse damage (HP loss from Pain cards in hand)
-- - Enhanced logging for shadow copy executions
--
-- This pipeline runs for BOTH original cards and shadow copies (duplications).
-- All triggers count equally - a shadow Strike increments Pen Nib just like the original.

local BeforeCardPlayed = {}

local Utils = require("utils")

function BeforeCardPlayed.execute(world, player, card)
    if not world or not player or not card then
        return
    end

    -- STATISTICS: Track Powers played this combat
    -- Used by future relics/mechanics that care about Power card count
    if card.type == "POWER" then
        world.combat.powersPlayedThisCombat = world.combat.powersPlayedThisCombat + 1

        -- STORM: Channel 1 Lightning when playing Power cards
        -- Triggers for ALL Power cards (including shadow copies)
        if player.status and player.status.storm and player.status.storm > 0 then
            world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Lightning"})
            table.insert(world.log, "Storm triggered!")
        end
    end

    -- PEN NIB: Increment attack counter
    -- ALL attacks increment this counter (including shadow copies from duplications)
    -- Counter is checked in DealAttackDamage.lua and reset in AfterCardPlayed.lua
    if card.type == "ATTACK" then
        world.penNibCounter = world.penNibCounter + 1
    end

    -- ENHANCED LOGGING: Shadow copy execution markers
    -- Makes it clear in the log when a duplication is executing vs the original card
    if card.isShadow then
        local source = card.duplicationSource or "Duplication"
        table.insert(world.log, "  → " .. card.originalCardName .. " (" .. source .. ")")
    end

    -- PAIN CURSE: Deal 1 HP per Pain card in hand
    -- Pain damage is queued with "FIRST" priority to process before the card's own effects
    -- This ensures Pain damage happens before any healing/defense the card might provide
    local handCards = Utils.getCardsByState(player.combatDeck, "HAND")
    local painCount = 0

    for _, handCard in ipairs(handCards) do
        if handCard.id == "Pain" then
            painCount = painCount + 1
        end
    end

    if painCount > 0 then
        -- Queue each point of Pain damage individually
        -- This allows proper interaction with damage reduction effects
        for i = 1, painCount do
            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = "Pain",
                target = player,
                amount = 1,
                tags = {"ignoreBlock"}
            }, "FIRST")  -- FIRST priority ensures Pain processes before card effects
        end

        table.insert(world.log, player.name .. " loses " .. painCount .. " HP from Pain in hand")
    end

    -- Future hooks can be added here:
    -- - Other relics that trigger on card play
    -- - Status effects that modify card behavior
    -- - Pre-play damage/effects
end

return BeforeCardPlayed
