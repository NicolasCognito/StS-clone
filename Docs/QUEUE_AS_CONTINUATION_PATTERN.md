# Queue as Continuation Pattern

**Date:** 2025-11-15
**Context:** Fix for Well-Laid Plans hanging bug
**Pattern Type:** Control Flow Architecture

---

## The Problem

When a pipeline needs user input (context) mid-execution, it must:
1. Pause execution
2. Wait for user input
3. Resume exactly where it left off

**The Bug:** EndTurn.lua requested context for card selection (Well-Laid Plans), but continued executing and discarded all cards before the user could make a selection.

```lua
// BROKEN FLOW:
EndTurn.execute()
  → Push COLLECT_CONTEXT to queue
  → ProcessEventQueue.execute() returns {needsContext = true}
  → ❌ Return value IGNORED
  → ❌ Code keeps running, discards all cards
  → Game hangs (context request set, but cards are gone)
```

---

## The Solution: Queue as Continuation

**Core Insight:** The event queue is FIFO. If we put "rest of the work" into the queue AFTER the context request, it won't execute until context is collected!

```lua
// FIXED FLOW:
EndTurn.execute()
  → Push COLLECT_CONTEXT to queue (FIRST priority)
  → Push ON_CUSTOM_EFFECT (mark retained cards)
  → Push ON_CUSTOM_EFFECT (discard hand and cleanup) ← The continuation!
  → ProcessEventQueue.execute()

If no context exists yet:
  → COLLECT_CONTEXT pauses, returns {needsContext = true}
  → EndTurn propagates return value to CombatEngine
  → CombatEngine collects context from user
  → CombatEngine loop resumes
  → ProcessEventQueue continues processing
  → Mark retained cards (uses collected context)
  → Discard hand and cleanup (runs AFTER context!)
  ✅ Cards only discarded after user makes selection
```

---

## Implementation Pattern

### Step 1: Extract Continuation Logic

Move the "rest of the work" into a helper function:

```lua
function Pipeline.continueExecution(world, ...)
    -- All the code that should run AFTER context is collected
    -- This used to be at the end of the main function
end
```

### Step 2: Queue the Continuation

```lua
function Pipeline.execute(world, ...)
    -- Early logic (before context needed)
    -- ...

    if needsUserInput then
        -- Step 1: Request context (FIRST priority)
        world.queue:push({
            type = "COLLECT_CONTEXT",
            contextProvider = {...}
        }, "FIRST")

        -- Step 2: Use context (runs after collection)
        world.queue:push({
            type = "ON_CUSTOM_EFFECT",
            effect = function()
                -- Use world.combat.tempContext or stableContext here
            end
        })

        -- Step 3: Queue the continuation!
        world.queue:push({
            type = "ON_CUSTOM_EFFECT",
            effect = function()
                Pipeline.continueExecution(world, ...)
            end
        })

        -- Process queue - might pause for context
        local result = ProcessEventQueue.execute(world)
        if type(result) == "table" and result.needsContext then
            return result  -- Propagate to caller
        end

        -- If we get here, everything completed
        return
    end

    -- Normal path (no context needed)
    Pipeline.continueExecution(world, ...)
end
```

### Step 3: Caller Handles Pause

```lua
// CombatEngine or other caller:
local result = Pipeline.execute(world, ...)
if type(result) == "table" and result.needsContext then
    // Don't proceed with next steps
    // Context request will be handled on next loop iteration
else
    // Pipeline completed, continue with next actions
end
```

---

## Why This Works

### Queue Execution Order Guarantees

The event queue processes events in **FIFO order** (with "FIRST" priority exception):

```
Queue state when ProcessEventQueue is called:
┌────────────────────────────────────────┐
│ 1. COLLECT_CONTEXT (FIRST)            │ ← Processes first
│ 2. ON_CUSTOM_EFFECT (use context)     │ ← Waits in queue
│ 3. ON_CUSTOM_EFFECT (continuation)    │ ← Waits in queue
└────────────────────────────────────────┘

If context doesn't exist:
  → COLLECT_CONTEXT is put BACK at front (FIRST)
  → ProcessEventQueue returns {needsContext = true}
  → Items 2 and 3 NEVER execute yet ✅

After context is collected:
  → COLLECT_CONTEXT finds context, consumes event
  → Item 2 executes (uses collected context)
  → Item 3 executes (continuation runs)
  ✅ Perfect ordering guaranteed
```

### Closure Captures State

The continuation function is a **closure** - it captures the local variables from when it was created:

```lua
function EndTurn.execute(world, player)
    local hasEstablishment = Utils.hasPower(player, "Establishment")  -- Captured!

    world.queue:push({
        type = "ON_CUSTOM_EFFECT",
        effect = function()
            -- This closure can access hasEstablishment
            EndTurn.discardHandAndCleanup(world, player)
        end
    })
end
```

---

## Comparison with Other Approaches

| Approach | Code Changes | Complexity | Resumption |
|----------|--------------|------------|------------|
| **Queue as Continuation** | Minimal (extract helper) | Low | Automatic (via queue) |
| Coroutines | High (wrap in coroutines) | Medium | Manual (resume) |
| Manual Propagation | Low (return checks) | Low | Manual (re-call) |
| Multi-Phase Pipelines | Very High (refactor) | High | Manual (phase tracking) |

---

## When to Use This Pattern

✅ **Use when:**
- Pipeline needs context mid-execution
- Logic after context collection is complex (many steps)
- You want to avoid coroutines
- Queue-based architecture already in place

❌ **Don't use when:**
- Context needed at the very start (just return early)
- Continuation is trivial (1-2 lines)
- Pipeline is called frequently (closure overhead)

---

## Example: EndTurn with Well-Laid Plans

### Before (Broken):

```lua
function EndTurn.execute(world, player)
    -- ... early logic ...

    if player.status.well_laid_plans then
        world.queue:push({type = "COLLECT_CONTEXT", ...}, "FIRST")
        world.queue:push({type = "ON_CUSTOM_EFFECT", ...})  -- Mark retained
        ProcessEventQueue.execute(world)  // Returns {needsContext=true}
        // ❌ Return value ignored!
    end

    // ❌ This always runs!
    for _, card in ipairs(player.combatDeck) do
        world.queue:push({type = "ON_DISCARD", card = card})  // Discards before user selects!
    end
end
```

### After (Fixed):

```lua
function EndTurn.discardHandAndCleanup(world, player)
    -- Extracted continuation logic
    for _, card in ipairs(player.combatDeck) do
        if card.retain or card.retainThisTurn then
            -- Keep card
        else
            world.queue:push({type = "ON_DISCARD", card = card})
        end
    end
    // ... cleanup logic ...
end

function EndTurn.execute(world, player)
    -- ... early logic ...

    if player.status.well_laid_plans then
        world.queue:push({type = "COLLECT_CONTEXT", ...}, "FIRST")
        world.queue:push({type = "ON_CUSTOM_EFFECT", ...})  // Mark retained

        // ✅ Queue the continuation!
        world.queue:push({
            type = "ON_CUSTOM_EFFECT",
            effect = function()
                EndTurn.discardHandAndCleanup(world, player)
            end
        })

        local result = ProcessEventQueue.execute(world)
        if type(result) == "table" and result.needsContext then
            return result  // ✅ Propagate pause
        end
        return  // ✅ Early return if completed
    end

    // Normal path
    EndTurn.discardHandAndCleanup(world, player)
end
```

---

## Implementation Checklist

When applying this pattern:

- [ ] Extract continuation logic into helper function
- [ ] Push COLLECT_CONTEXT with "FIRST" priority
- [ ] Push context usage as ON_CUSTOM_EFFECT
- [ ] Push continuation as ON_CUSTOM_EFFECT (closure)
- [ ] Check and propagate ProcessEventQueue return value
- [ ] Update caller to handle {needsContext = true}
- [ ] Add normal path for when context not needed
- [ ] Test with context collection scenario

---

## Architectural Benefits

1. **Separation of Concerns:** Queue handles scheduling, pipelines focus on logic
2. **Declarative:** "Do this, then that" reads naturally
3. **Composable:** Can chain multiple context requests
4. **Testable:** Continuations are regular functions
5. **Debuggable:** Queue inspection shows pending work

---

## Applications

This pattern has been applied to these pipelines:

### 1. EndTurn with Well-Laid Plans
- **Pattern:** Context collection mid-execution
- **Challenge:** Needed to select cards to retain before discarding hand
- **Solution:** Queue continuation after context collection

### 2. StartTurn with Multiple Context Collections
- **Pattern:** Sequential context collections
- **Challenge:** Foresight (scry before draw), Tools of Trade (draw+discard after draw), Gambling Chip (mulligan first turn)
- **Solution:** Queue ALL work up front with multiple COLLECT_CONTEXT events, each pauses in sequence
- **Implementation:** `Pipelines/StartTurn.lua:124-236` (queueTurnStartWithContext)

**Key Insight:** Multiple COLLECT_CONTEXT events in the queue will pause sequentially, with ProcessEventQueue resuming after each context is collected.

## Future Applications

This pattern can be applied to any pipeline needing mid-execution context:

- **Discovery:** "Generate 3 cards, let user pick 1, then add to hand"
- **Custom Events:** "Show options, wait for choice, then execute effects"

---

## Related Patterns

- **Continuation-Passing Style (CPS):** Functional programming pattern
- **Command Pattern:** Queue holds commands to execute
- **Promise/Future:** Async computation with deferred result

---

**Conclusion:** The "Queue as Continuation" pattern leverages the event queue's FIFO ordering to achieve pause/resume semantics without coroutines or complex state machines. It's a clean, queue-native solution for mid-execution context collection.
