-- PLAY CARD PIPELINE
-- Orchestrates the execution of a card from hand
--
-- ARCHITECTURE:
-- This pipeline is the main orchestrator - it delegates to specialized pipelines and helpers:
--   - IsPlayable.lua: Validates card can be played
--   - BeforeCardPlayed.lua: Pre-execution hooks (Pen Nib, Pain, Storm, etc.)
--   - AfterCardPlayed.lua: Post-execution hooks (card limits, Choked, etc.)
--   - PlayCard_DuplicationHelpers.lua: Duplication planning (Double Tap, Echo Form, etc.)
--   - PlayCard_Helpers.lua: Supporting functions (cleanup, cost calculation, logging)
--
-- EXECUTION FLOW:
-- 1. Playability check (IsPlayable)
-- 2. Energy payment and cost calculation
-- 3. Pre-play action hook (card.prePlayAction)
-- 4. Duplication planning (creates shadow copies)
-- 5. Queue card entries to CardQueue (LIFO stack)
-- 6. For each execution (original + shadows):
--    a. BeforeCardPlayed triggers
--    b. card.onPlay() generates events
--    c. Process EventQueue
--    d. AfterCardPlayed triggers
--    e. Handle card cleanup (exhaust or discard)
--
-- CONTEXT SYSTEM:
-- - Cards request context via COLLECT_CONTEXT events in their onPlay
-- - Context can be "stable" (persists across duplications) or "temp" (re-collected)
-- - PlayCard pauses execution when context is needed, resumes after collection
--
-- SHADOW COPIES:
-- - Duplications create real card instances (shadows) stored in world.DuplicationShadowCards
-- - Each shadow executes independently: calls onPlay, triggers hooks, handles cleanup
-- - All shadows are purged at end of turn

local PlayCard = {}

local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
local GetCost = require("Pipelines.GetCost")
local IsPlayable = require("Pipelines.IsPlayable")
local Utils = require("utils")
local DuplicationHelpers = require("Pipelines.PlayCard_DuplicationHelpers")
local ClearContext = require("Pipelines.ClearContext")
local ContextProvider = require("Pipelines.ContextProvider")
local BeforeCardPlayed = require("Pipelines.BeforeCardPlayed")
local Helpers = require("Pipelines.PlayCard_Helpers")

local function enterProcessingState(card)
    if card.state ~= "PROCESSING" then
        if card._previousState == nil then
            card._previousState = card.state
        end
        card.state = "PROCESSING"
    end
end

local function revertProcessingState(card)
    if card._previousState then
        card.state = card._previousState
        card._previousState = nil
    elseif card.state == "PROCESSING" then
        card.state = "HAND"
    end
end

local function prepareCardPlay(world, player, card, options)
    options = options or {}

    -- STEP 1: CHECK PLAYABILITY
    local playable, errorMsg = IsPlayable.execute(world, player, card, options)
    if not playable then
        table.insert(world.log, errorMsg)
        return false
    end

    local auto = options.auto or options.skipEnergyCost or false  -- Support both names for compatibility
    local costWhenPlayedOverride = options.costWhenPlayedOverride

    -- STEP 2: CALCULATE CARD COST
    -- Determine actual energy cost (may be overridden by effects)
    local cardCost = costWhenPlayedOverride or GetCost.execute(world, player, card)

    -- STEP 3: PRE-PLAY ACTION (Optional hook for cards)
    if card.prePlayAction then
        card:prePlayAction(world, player)
    end

    -- STEP 4: PAY ENERGY (skip for auto-play)
    if not auto then
        player.energy = player.energy - cardCost
    end

    -- STEP 5: LOG CARD PLAY
    local logMessage = Helpers.formatPlayLog(player, card, options, cardCost)
    table.insert(world.log, logMessage)

    -- STEP 6: SET COST INFORMATION ON CARD
    -- This info is used by the card's onPlay and other systems
    card.costWhenPlayed = cardCost
    card.energySpent = Helpers.calculateEnergySpent(world, player, card, cardCost, options)
    card.energyPaid = true

    -- STEP 7: ENTER PROCESSING STATE
    enterProcessingState(card)
    return true
end

local function finalizeCardPlay(world, card)
    -- Clean up temporary card flags
    -- Stable context is cleared by separators, not here
    card.energyPaid = nil
    card._runActive = nil
    card._previousState = nil
    card._effectInitialized = nil
end

local function enqueueCardEntries(world, player, card, options)
    local queue = world.cardQueue
    if not queue then
        error("Card queue is not initialized. Did you forget to start combat?")
    end

    local prepared = prepareCardPlay(world, player, card, options)
    if prepared ~= true then
        return prepared
    end

    -- Build duplication plan
    local replayPlan = DuplicationHelpers.buildReplayPlan(world, player, card)

    -- Create shadow copies for each duplication
    -- Shadow copies are REAL card instances that inherit all prepared state from the original
    local shadowCopies = {}
    local loggedSources = {}  -- Track which sources we've logged
    for i, sourceName in ipairs(replayPlan) do
        -- Log duplication trigger (once per source)
        if not loggedSources[sourceName] then
            table.insert(world.log, sourceName .. " triggers!")
            loggedSources[sourceName] = true
        end

        local shadow = Utils.deepCopyCard(card)
        shadow.isShadow = true
        shadow.id = Utils.generateGUID()  -- Unique ID for tracking
        shadow.originalCardName = card.name
        shadow.duplicationSource = sourceName  -- "Double Tap", "Echo Form", etc.
        -- Shadow inherits all prepared state from original
        shadow.costWhenPlayed = card.costWhenPlayed
        shadow.energySpent = card.energySpent
        shadow.energyPaid = card.energyPaid
        shadow.state = "PROCESSING"
        -- Shadow should NOT inherit execution state flags
        shadow._effectInitialized = nil

        table.insert(world.DuplicationShadowCards, shadow)
        table.insert(shadowCopies, shadow)
    end

    -- Push entries to CardQueue (LIFO) with separators bracketing the execution group
    -- Separators ensure stable context is cleared before and after this card+duplicates

    -- Bottom separator: clears stable context AFTER this card group finishes (pops last)
    queue:pushSeparator()

    -- Push shadow copies in reverse order (LIFO) so they execute before the original
    for i = #shadowCopies, 1, -1 do
        queue:push({
            card = shadowCopies[i],
            player = player,
            options = options
        })
    end

    -- Push original card entry (always executes, shadows are additional plays)
    queue:push({
        card = card,
        player = player,
        options = options
    })

    -- Top separator: clears stable context BEFORE this card group starts (pops first)
    queue:pushSeparator()

    card._runActive = true
    return true
end

-- EXECUTE CARD EFFECT
-- Executes a card's effect. Works with both original cards and shadow copies.
-- Each card (original or shadow) is executed independently with full game mechanics.
function PlayCard.executeCardEffect(world, player, card, options)
    options = options or {}

    -- Only execute effect and push events if not already initialized
    -- This prevents duplicate event pushing when resuming after context collection
    if not card._effectInitialized then
        card._effectInitialized = true

        -- BEFORE CARD PLAYED PIPELINE
        -- Handles: Statistics tracking, Pen Nib counter, Pain damage, Storm, shadow logging
        BeforeCardPlayed.execute(world, player, card)

        -- EXECUTE CARD EFFECT
        -- Call the card's onPlay function to generate its events
        if card.onPlay then
            card:onPlay(world, player)
        end

        -- TRACK CURRENT EXECUTING CARD
        -- Store card metadata for AfterCardPlayed to access
        world.combat.currentExecutingCard = {
            type = card.type,
            name = card.isShadow and card.originalCardName or card.name,
            isShadow = card.isShadow
        }

        -- QUEUE AFTER CARD PLAYED EVENT
        -- This triggers post-execution hooks (Pen Nib reset, Choked damage, card limits, etc.)
        world.queue:push({
            type = "AFTER_CARD_PLAYED",
            player = player
        })
    end

    -- PROCESS EVENT QUEUE
    -- Always run this, even when resuming after context collection
    local queueResult = ProcessEventQueue.execute(world)
    if type(queueResult) == "table" and queueResult.needsContext then
        return queueResult
    end

    -- CARD CLEANUP
    -- Determine if card should exhaust or discard and handle it
    -- Exhaust conditions: forcedExhaust, card.exhausts = true, or (Corruption power + Skill card)
    return Helpers.handleCardCleanup(world, player, card, options)
end

local function resolveEntry(world, entry)
    if not entry then
        return nil
    end

    -- Handle separator entries (skip them - they're handled by ResolveCard)
    if entry.type == "SEPARATOR" then
        return true
    end

    local card = entry.card
    local player = entry.player

    -- STABLE CONTEXT VALIDATION
    -- Check if stable context is still valid before executing card
    if card.stableContextValidator then
        local isValid = card.stableContextValidator(world, world.combat.stableContext, card)

        if not isValid then
            -- Give card a chance to fix invalid context
            if card.onStableContextInvalidated then
                card:onStableContextInvalidated(world)
            end

            -- Re-validate after giving card a chance to fix
            isValid = card.stableContextValidator(world, world.combat.stableContext, card)

            if not isValid then
                -- Still invalid - cancel card execution
                local cardName = card.isShadow and card.originalCardName or card.name
                table.insert(world.log, cardName .. " canceled - target no longer valid")

                -- Finalize original card (shadows are cleaned up at end of turn)
                if not card.isShadow then
                    finalizeCardPlay(world, card)
                end

                return true  -- Return success to continue processing queue
            end
        end
    end

    -- Execute the card effect
    local options = entry.options or {}
    local result = PlayCard.executeCardEffect(world, player, card, options)
    if type(result) == "table" and result.needsContext then
        -- Need context - push entry back to queue to resume later
        entry.resuming = true
        world.cardQueue:push(entry)
        return result
    end

    -- Finalize original card after execution (shadows are cleaned up at end of turn)
    if not card.isShadow then
        finalizeCardPlay(world, card)
    end

    return true
end

function PlayCard.resolveQueuedEntry(world, entry)
    return resolveEntry(world, entry)
end

function PlayCard.execute(world, player, card, options)
    options = options or {}

    -- Auto-cast mode: automatically handle context collection
    if options.auto then
        while true do
            -- Enqueue card if not already active
            if not card._runActive then
                local enqueueResult = enqueueCardEntries(world, player, card, options)
                if enqueueResult ~= true then
                    revertProcessingState(card)
                    return enqueueResult
                end
            end

            -- Process event queue
            local queueResult = ProcessEventQueue.execute(world)

            -- If no context needed, we're done
            if queueResult == true then
                return true
            end

            -- If context needed, automatically collect it
            if type(queueResult) == "table" and queueResult.needsContext then
                local request = world.combat and world.combat.contextRequest
                if not request then
                    revertProcessingState(card)
                    return false
                end

                -- Auto-collect context
                local context = ContextProvider.execute(world, player, request.contextProvider, request.card)
                if not context then
                    world.combat.contextRequest = nil
                    revertProcessingState(card)
                    return false
                end

                -- Store context based on stability
                if request.stability == "stable" then
                    world.combat.stableContext = context
                else
                    world.combat.tempContext = context
                end

                world.combat.contextRequest = nil
                -- Continue loop to process with collected context
            else
                -- Unexpected result
                revertProcessingState(card)
                return queueResult
            end
        end
    else
        -- Normal mode: return to caller when context is needed
        if not card._runActive then
            local enqueueResult = enqueueCardEntries(world, player, card, options)
            if enqueueResult ~= true then
                return enqueueResult
            end
        end

        local queueResult = ProcessEventQueue.execute(world)
        if type(queueResult) == "table" and queueResult.needsContext then
            return queueResult
        end

        return true
    end
end

function PlayCard.queueForcedReplay(card, sourceName, count)
    count = count or 1
    if count <= 0 then
        return
    end

    card._forcedReplays = card._forcedReplays or {}
    for _ = 1, count do
        table.insert(card._forcedReplays, sourceName or "Forced Replay")
    end
end

return PlayCard
