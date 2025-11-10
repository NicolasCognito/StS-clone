-- PLAY CARD PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card from hand to play
-- providedContext: optional pre-provided context (enemy entity, cards array, or nil)
--                  If nil, will be auto-collected by ContextProvider
--
-- Context parameter passed to card.onPlay:
-- - For "enemy" context: enemy entity
-- - For card selection contexts: array of cards (always array, even for single card)
-- - For "none" context: nil
--
-- Handles:
-- - Check energy cost
-- - Check custom playability (if card has isPlayable function)
-- - Execute pre-play action (if card has prePlayAction function)
-- - Collect context (via ContextProvider if not provided)
-- - Pay energy cost
-- - Track combat statistics (Powers played, etc.)
-- - Call card.onPlay to generate events
-- - Process effect queue
-- - Remove card from hand
-- - Add to discard pile (or exhaust if Corruption + Skill)
-- - Combat logging
--
-- Custom Playability:
-- Some cards (Grand Finale, etc.) have special requirements beyond energy.
-- If card.isPlayable exists, it's called to validate if card can be played.
-- Returns: true if playable, false + optional error message if not.
--
-- Pre-Play Actions:
-- Some cards (Discovery, etc.) need to set up choices BEFORE context collection.
-- If card.prePlayAction exists, it's called before ContextProvider.execute().
-- Example: Discovery generates 3 random cards with state="DRAFT", then contextProvider
--          filters for DRAFT cards for player to choose from.
--
-- Post-Play Phase:
-- Some cards (Dagger Throw, etc.) need to prompt for additional input AFTER the main effect.
-- If card.postPlayContext exists, the card will prompt for additional context after playing.
-- Card must define:
--   - postPlayContext: same format as contextProvider ("enemy", {card selection config}, etc.)
--   - postPlayEffect: function(self, world, player, postContext, originalContext)
-- The postPlayEffect receives both the post-play context and the original play context.

local PlayCard = {}

local ProcessEffectQueue = require("Pipelines.ProcessEffectQueue")
local GetCost = require("Pipelines.GetCost")
local ContextProvider = require("Pipelines.ContextProvider")
local Utils = require("utils")
local DuplicationHelpers = require("Pipelines.PlayCard_DuplicationHelpers")

-- EXECUTE CARD EFFECT (Steps 6-9)
-- This is the "bracketed section" that gets replayed for effects like Double Tap
-- skipDiscard: if true, don't move card to discard pile (for replays where card is already in a pile)
function PlayCard.executeCardEffect(world, player, card, context, skipDiscard)
    -- STEP 6: TRACK STATISTICS
    -- Track combat statistics
    if card.type == "POWER" then
        world.combat.powersPlayedThisCombat = world.combat.powersPlayedThisCombat + 1
    end

    -- Increment Pen Nib counter for Attack cards
    if card.type == "ATTACK" then
        world.penNibCounter = world.penNibCounter + 1
    end

    -- STEP 7: EXECUTE CARD EFFECT
    -- Call card's onPlay function with context
    -- Context can be: enemy entity, cards array, or nil (depending on contextType)
    if card.onPlay then
        card:onPlay(world, player, context)
    end

    -- Push AfterCardPlayed event to queue (processed after card effects)
    world.queue:push({
        type = "AFTER_CARD_PLAYED",
        player = player
    })

    -- STEP 8: PROCESS EFFECT QUEUE
    -- Process all events from the queue
    ProcessEffectQueue.execute(world)

    -- STEP 9: CARD CLEANUP (Discard or Exhaust)
    -- Determine where card goes after being played
    -- Check if card should be exhausted (Corruption for Skills, or card has exhaust property)
    local shouldExhaust = false
    local exhaustSource = nil

    -- Corruption: Skills are exhausted
    if Utils.hasPower(player, "Corruption") and card.type == "SKILL" then
        shouldExhaust = true
        exhaustSource = "Corruption"
    end

    -- TODO: Card-specific exhaust (e.g., Offering, True Grit+, etc.)
    -- if card.exhausts then
    --     shouldExhaust = true
    --     exhaustSource = "SelfExhaust"
    -- end

    if shouldExhaust then
        -- Push exhaust event to queue
        world.queue:push({
            type = "ON_EXHAUST",
            card = card,
            source = exhaustSource
        })
        ProcessEffectQueue.execute(world)
    elseif not skipDiscard then
        -- Normal discard via event queue (skip for replays where card is already in a pile)
        world.queue:push({
            type = "ON_DISCARD",
            card = card,
            player = player
        })
        ProcessEffectQueue.execute(world)
    end
end

function PlayCard.execute(world, player, card, providedContext)
    -- STEP 1: CHECK ENERGY
    -- Get the current cost of the card (allows for dynamic cost calculation)
    local cardCost = GetCost.execute(world, player, card)

    -- Check if player has enough energy (but don't pay yet)
    if player.energy < cardCost then
        table.insert(world.log, "Not enough energy to play " .. card.name)
        return false
    end

    -- STEP 2: CHECK CUSTOM PLAYABILITY (Optional)
    -- Some cards have special requirements (e.g., Grand Finale: deck must be empty)
    if card.isPlayable then
        local playable, errorMsg = card:isPlayable(world, player)
        if not playable then
            table.insert(world.log, errorMsg or ("Cannot play " .. card.name))
            return false
        end
    end

    -- STEP 3: PRE-PLAY ACTION (Optional)
    -- Execute pre-play setup if card defines it
    -- Used for cards like Discovery that generate choices before context collection
    if card.prePlayAction then
        card:prePlayAction(world, player)
    end

    -- STEP 4: COLLECT CONTEXT
    -- Get context via ContextProvider if not explicitly provided
    local context = providedContext
    if context == nil then
        context = ContextProvider.execute(world, player, card)
    end

    -- Validate that context exists when needed
    local contextType = ContextProvider.getContextType(card)
    if contextType ~= "none" and context == nil then
        table.insert(world.log, "Card " .. card.name .. " requires context of type " .. contextType)
        return false
    end

    -- STEP 5: PAY ENERGY
    -- Now that we know the card can be played, pay the cost
    player.energy = player.energy - cardCost
    table.insert(world.log, player.id .. " played " .. card.name .. " (cost: " .. cardCost .. ")")

    -- Store energy spent for X cost cards (e.g., Whirlwind, Skewer)
    -- Card can access this value in onPlay via self.energySpent
    card.energySpent = cardCost

    -- Store cost when played for Necronomicon checking
    card.costWhenPlayed = cardCost

    -- Chemical X: Add bonus to X cost cards
    if card.cost == "X" then
        local chemicalX = Utils.getRelic(player, "Chemical_X")
        if chemicalX then
            card.energySpent = card.energySpent + chemicalX.xCostBonus
            table.insert(world.log, "Chemical X activated! (X + " .. chemicalX.xCostBonus .. ")")
        end
    end

    -- STEPS 6-9: Execute the card effect (the "bracketed section")
    -- This can be replayed by duplication effects
    PlayCard.executeCardEffect(world, player, card, context, false)

    -- DUPLICATION LOOP
    -- Check all duplication sources and replay card as needed
    -- Sources: Duplication Potion, Double Tap, Burst, Amplify, Echo Form, Necronomicon
    while true do
        local shouldReplay, source = DuplicationHelpers.shouldBePlayedAgain(world, player, card)
        if not shouldReplay then
            break
        end

        table.insert(world.log, source .. " triggers!")
        PlayCard.executeCardEffect(world, player, card, context, true)  -- skipDiscard=true
    end

    -- Check if card needs post-play phase
    if card.postPlayContext then
        -- Store original context for post-play effect
        card.originalPlayContext = context

        -- Return special value to indicate post-play is needed
        return {success = true, needsPostPlay = true}
    end

    return true
end

-- EXECUTE POST-PLAY PHASE
-- Called after the main card play when card has postPlayContext
-- world: the complete game state
-- player: the player character
-- card: the card that was played
-- providedPostContext: optional pre-provided post-play context
--                      If nil, will be auto-collected by ContextProvider
function PlayCard.executePostPlay(world, player, card, providedPostContext)
    -- STEP 1: COLLECT POST-PLAY CONTEXT
    -- Get context via ContextProvider if not explicitly provided
    local postContext = providedPostContext
    if postContext == nil then
        postContext = ContextProvider.execute(world, player, card, "postPlayContext")
    end

    -- Validate that context exists when needed
    local postContextType = ContextProvider.getContextType(card, "postPlayContext")
    if postContextType ~= "none" and postContext == nil then
        table.insert(world.log, "Card " .. card.name .. " post-play requires context of type " .. postContextType)
        return false
    end

    -- STEP 2: EXECUTE POST-PLAY EFFECT
    -- Call card's postPlayEffect function with both contexts
    -- originalPlayContext was stored during the main play
    if card.postPlayEffect then
        card:postPlayEffect(world, player, postContext, card.originalPlayContext)
    end

    -- STEP 3: PROCESS EFFECT QUEUE
    ProcessEffectQueue.execute(world)

    -- STEP 4: CHECK FOR DUPLICATION (reuse shouldBePlayedAgain)
    -- This handles all duplication sources automatically
    local shouldReplay, source = DuplicationHelpers.shouldBePlayedAgain(world, player, card)
    if shouldReplay then
        table.insert(world.log, source .. " triggers! (post-play)")
        return {needsPostPlay = true}  -- Continue duplication loop
    end

    -- Clean up stored context - all replays complete
    card.originalPlayContext = nil

    return true
end

return PlayCard
