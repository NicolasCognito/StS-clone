-- IS PLAYABLE PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card to check for playability
-- options: optional table with:
--   - auto: if true, skip energy and play limit checks (for auto-cast cards)
--   - skipEnergyCost: alias for auto (backward compatibility)
--
-- Handles:
-- - Check if a card can be played in the current game state
-- - Priority order of checks:
--   1. Energy already paid (card is being re-played)
--   2. Entangled status (prevents playing Attacks)
--   3. Card play limit per turn (Velvet Choker, Normality)
--   4. Energy availability
--   5. Custom card.isPlayable function (card-specific rules)
--
-- Returns:
--   playable (boolean): true if card can be played
--   errorMsg (string): nil if playable, error message if not
--
-- This is the centralized place for all playability checking logic

local IsPlayable = {}

local GetCost = require("Pipelines.GetCost")
local Utils = require("utils")

function IsPlayable.execute(world, player, card, options)
    options = options or {}
    local auto = options.auto or options.skipEnergyCost or false

    -- CHECK 1: Already paid for (card is being replayed/resumed)
    -- If energy is already paid, card is playable (we're in the middle of execution)
    if card.energyPaid then
        return true, nil
    end

    -- CHECK 2: Entangled status (prevents playing Attacks)
    player.status = player.status or {}
    if card.type == "ATTACK" and player.status.entangled and player.status.entangled > 0 then
        return false, player.name .. " is Entangled and cannot play attacks"
    end

    -- CHECK 3: Card play limit per turn (skip for auto-cast cards)
    -- Auto-cast cards like Havoc were already validated when played
    if world.combat and not auto then
        local limit = Utils.getCardPlayLimit(world, player)
        if world.combat.cardsPlayedThisTurn >= limit then
            return false, "Cannot play more than " .. limit .. " cards this turn"
        end
    end

    -- CHECK 4: Energy availability (skip for auto-cast cards)
    if not auto then
        local cardCost = options.costWhenPlayedOverride or GetCost.execute(world, player, card)
        if player.energy < cardCost then
            return false, "Not enough energy to play " .. card.name
        end
    end

    -- CHECK 5: Custom card playability function
    -- Cards can define custom rules (e.g., requiring a target, specific game state, etc.)
    if card.isPlayable then
        local playable, errorMsg = card:isPlayable(world, player)
        if not playable then
            return false, errorMsg or ("Cannot play " .. card.name)
        end
    end

    -- All checks passed
    return true, nil
end

return IsPlayable
