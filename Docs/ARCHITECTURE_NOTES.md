# StS Clone Architecture: Pragmatic Compromise

## The Original Philosophy

The [Centralized Pipeline Architecture Philosophy](./centralized-pipeline-architecture.md) advocates for:
- **Pure data** for 95% of entities
- **Hardcoded logic** in centralized pipelines
- **One place per verb** - DealDamage, ApplyBlock, PlayCard, etc.

## Our Implementation: Pragmatic Balance

We've chosen a **pragmatic compromise** that honors the philosophy while acknowledging practical realities:

### Delta Functions in Card Data (Not Pure Data)

Instead of pure data:
```lua
-- Pure data (philosophy ideal)
Strike = { id = "Strike", damage = 6, cost = 1 }
-- PlayCard needs to interpret: "has damage? call DealDamage"
```

We use delta functions:
```lua
-- Delta functions (pragmatic approach)
Strike = {
    id = "Strike",
    damage = 6,
    cost = 1,

    onPlay = function(self, world, player, target)
        world.queue:push({
            type = "ON_DAMAGE",
            attacker = player,
            defender = target,
            card = self
        })
    end,

    onUpgrade = function(self)
        self.damage = 8
    end
}
```

### Why This Compromise Is Still Aligned With Philosophy

1. **Visibility is Preserved**
   - All card behavior is defined IN the card data
   - No hidden logic behind interfaces or polymorphism
   - You can see exactly what each card does in one place

2. **Centralized Pipeline Logic Remains**
   - DealDamage pipeline is still ONE place for all damage interactions
   - ApplyBlock pipeline is still ONE place for all block logic
   - Pipelines handle ALL the complexity: vulnerabilities, weak, strength, block absorption, etc.
   - Cards just "say what they want to do" via events

3. **No Abstraction Tax**
   - Cards don't inherit from abstract classes
   - No polymorphic dispatch overhead
   - Cards are still mostly data + simple functions
   - Adding card #301 takes minutes, not hours

4. **Queue-Based Event System**
   - Cards push events, they don't execute effects
   - All effects are processed through ProcessEffectQueue
   - This routes to ONE pipeline per effect type
   - Interactions happen in ONE place (DealDamage, ApplyBlock, etc.)

### The Flow (Still Centralized)

```
Card.onPlay()
    ↓ (pushes)
Queue.push({ type: ON_DAMAGE, ... })
    ↓ (ProcessEffectQueue drains)
DealDamage.execute(event)  ← ONE PLACE for all damage logic
    ↓ (hardcoded effects)
Apply strength multiplier
Apply block absorption
Reduce HP
Log everything
```

**The pipeline layer is still the single source of truth for game interactions.**

### Where Delta Functions Are Localized

Delta functions exist at exactly TWO points:

1. **Card Definition** - onPlay, onUpgrade
2. **Relic Definition** - onEndCombat
3. **Enemy Definition** - executeIntent

All delta functions do ONE thing: **push an event to the queue**.

They don't contain game logic. They don't calculate damage. They don't apply effects. They just say "here's what happened."

### When Pipelines Get Complex (They Will)

When we add Strength status effect:

**Card says**: "I want to deal damage"
**DealDamage pipeline adds**: Strength multiplier logic

**Bad approach (Abstract classes)**: Change 50 card classes to pass strength info
**Our approach**: DealDamage reads `card.strengthMultiplier` - done in one place

When we add Vulnerable:

**Card says**: "I want to deal damage"
**DealDamage pipeline adds**: Vulnerable multiplier logic

Same pattern. Card behavior stays dumb. Pipeline stays ONE place.

### Pragmatism Over Purity

The philosophy document itself acknowledges this:

> "**Pragmatism over purity**: Let delta functions mutate if that's the simplest expression. The key is **awareness and visibility** - you can Ctrl+F and find every mutation in seconds."

Our approach:
- ✅ Cards have small delta functions (onPlay, onUpgrade)
- ✅ They're visible and obvious
- ✅ They don't contain game logic
- ✅ All game logic is still in one pipeline per verb
- ✅ Extensibility through visibility, not modularity

### What We Avoid (The Torture)

We don't do:
- ❌ Abstract base classes for cards
- ❌ Polymorphic effects
- ❌ Strategy patterns
- ❌ Card classes inheriting and overriding methods
- ❌ Scattered logic across 350+ files

We still do:
- ✅ Explicit pipeline functions
- ✅ Hardcoded logic in one place per verb
- ✅ Visibility - you can see everything
- ✅ Simplicity - minimal indirection

## Summary

This is **pragmatic centralized pipeline architecture**:
- Cards + Enemies + Relics have delta functions for **event generation** only
- Pipelines contain all **game logic** in one visible place
- No abstraction layers, no polymorphism, no design patterns
- Still extensible, maintainable, and moddable through visibility

The philosophy remains intact. We've just found the sweet spot where simplicity (delta functions pushing events) meets centralization (all logic in pipelines).

---

## Evolved Architecture Patterns (Lessons from Implementation)

As we implemented Blood for Blood, Confused, Corruption, and other mechanics, key patterns emerged that strengthen the architecture:

### 1. Single Source of Truth for Cards

**Problem**: Separate `deck[]`, `hand[]`, `discard[]` arrays scatter cards across multiple locations.

**Solution**: Single `player.cards[]` table with `card.state` property.

```lua
-- BAD: Cards scattered across arrays
player.deck = {}
player.hand = {}
player.discard = {}

-- GOOD: Single source of truth
player.cards = {}  -- All cards here
-- Each card has: card.state = "DECK" | "HAND" | "DISCARD_PILE" | "EXHAUSTED_PILE"
```

**Benefits**:
- ✅ Can iterate ALL cards for cleanup (costsZeroThisTurn, confused, etc.)
- ✅ State transitions replace array moves (cleaner)
- ✅ No cards "hidden" in forgotten arrays
- ✅ Helper functions: `getCardsByState(player, "HAND")`

**Example**:
```lua
-- Clear costsZeroThisTurn from ALL cards, not just hand
for _, card in ipairs(player.cards) do
    if card.costsZeroThisTurn then
        card.costsZeroThisTurn = nil
    end
end
```

### 2. One Pipeline Per Major Mechanic

**Principle**: If a mechanic has multiple interactions, it deserves its own pipeline.

**Current Pipelines**:
- `GetCost` - Dynamic cost calculation (not `card.cost` direct access)
- `AcquireCard` - Adding cards mid-combat (not `table.insert(hand, card)`)
- `ApplyPower` - Applying powers (not `player.powers[x] = ...`)
- `StartTurn` - Turn-start logic (not scattered `block = 0` + `DrawCard`)
- `Exhaust` - Exhaust mechanics (not `card.state = "EXHAUSTED_PILE"`)

**Why**:
```lua
-- BAD: Direct manipulation
card.state = "EXHAUSTED_PILE"
table.insert(world.log, card.name .. " was exhausted (Corruption)")
-- Future: Dead Branch/Dark Embrace require finding all exhaust points

-- GOOD: Centralized pipeline
world.queue:push({ type = "ON_EXHAUST", card = card, source = "Corruption" })
-- Future: Add Dead Branch logic in ONE place (Exhaust.execute)
```

### 3. Tags Pattern for Variations

Following `DealDamage` with `tags = {"ignoreBlock"}`:

```lua
-- AcquireCard pipeline with tags
world.queue:push({
    type = "ON_ACQUIRE_CARD",
    player = player,
    cardTemplate = Cards.Strike,
    tags = {"costsZeroThisTurn"}  -- Reusable across cards
})

-- Exhaust pipeline with source tracking
world.queue:push({
    type = "ON_EXHAUST",
    card = card,
    source = "Corruption"  -- vs "SelfExhaust", "StrangeSpoon", etc.
})
```

**Pattern**: Use `tags[]` or `source` to track variations within same pipeline.

### 4. On-Demand Properties (Not Default)

**Problem**: Adding properties to every card is wasteful.

**Solution**: Add properties only when needed, clear globally.

```lua
-- Properties added on-demand:
card.confused = math.random(0, 3)      -- Only when Confused
card.costsZeroThisTurn = 1             -- Only when generated by Infernal Blade
card.state = "DECK"                     -- Always (required)

-- Clear from ALL cards (not just hand)
for _, card in ipairs(player.cards) do
    if card.costsZeroThisTurn then
        card.costsZeroThisTurn = nil  -- Remove property entirely
    end
end
```

**Why**: Properties are temporary overrides, not permanent card data.

### 5. Priority Systems in Pipelines

**GetCost** demonstrates priority-based logic:

```lua
-- Priority order (highest to lowest):
1. card.costsZeroThisTurn    -- Absolute override (Infernal Blade, potions)
2. Corruption power           -- Skills cost 0
3. card.confused              -- Random 0-3 (Snecko Eye)
4. card.cost                  -- Base cost (reference data)
5. costReductionPerHpLoss     -- Blood for Blood reduction

-- Reference data preserved:
card.cost = 4  -- Always preserved
card.confused = 2  -- Temporary override
-- GetCost returns 2, but card.cost is still 4
```

**Pattern**: Pipelines handle priority, cards stay simple data.

### 6. Don't Postpone Architectural Decisions

When a mechanic is introduced, establish its pattern immediately:

**Powers System**:
- Added `Data/Powers/Powers.lua` (like Cards.lua)
- Added `ApplyPower` pipeline (follows pattern)
- Powers stored in `player.powers[]` (checked in pipelines)

**StartTurn Pipeline**:
- Centralizes ALL turn-start logic
- Replaces scattered `player.block = 0` + `DrawCard.execute()`
- Ready for future turn-start power effects

**Why**: Delaying architecture creates inconsistency. Establish patterns early.

### 7. Preserve Reference Data

**Problem**: Overriding `card.cost` loses original value.

**Solution**: Temporary properties take priority in pipelines, original data preserved.

```lua
-- BAD: Lose reference
card.cost = 0  -- Original cost lost forever

-- GOOD: Preserve reference
card.cost = 4               -- Original (never changes)
card.confused = 2           -- Temporary override
-- GetCost checks: card.confused or card.cost
```

**Example**:
```lua
function GetCost.execute(world, player, card)
    if card.costsZeroThisTurn == 1 then return 0 end
    if hasPower(player, "Corruption") and card.type == "SKILL" then return 0 end

    local cost = card.confused or card.cost  -- Temporary or base

    if card.costReductionPerHpLoss then
        cost = cost - (world.combat.timesHpLost * card.costReductionPerHpLoss)
    end

    return math.max(0, cost)
end
```

### 8. Mechanic-Specific Pipelines Enable Future Features

**Exhaust Pipeline** makes these trivial:

```lua
function Exhaust.execute(world, event)
    local card = event.card

    -- TODO: Strange Spoon (50% prevent exhaust)
    -- if hasPower(player, "Strange_Spoon") and math.random() < 0.5 then
    --     return  -- Card not exhausted
    -- end

    card.state = "EXHAUSTED_PILE"

    -- TODO: Trigger exhaust-related effects
    -- - Dead Branch: Add random card to hand
    -- - Dark Embrace: Draw a card
    -- - Feel No Pain: Gain block
end
```

All exhaust interactions in ONE place. No hunting across codebase.

### 9. Consistent Event Routing

All pipelines follow same pattern:

```lua
-- Card pushes event
world.queue:push({
    type = "ON_ACQUIRE_CARD",  -- or ON_EXHAUST, ON_APPLY_POWER, etc.
    player = player,
    cardTemplate = Cards.Strike,
    tags = {"costsZeroThisTurn"}
})

-- ProcessEffectQueue routes to pipeline
elseif event.type == "ON_ACQUIRE_CARD" then
    AcquireCard.execute(world, event.player, event.cardTemplate, event.tags)
```

**No special cases**. Every mechanic follows the same flow.

### 10. Helper Functions for Common Patterns

```lua
-- Check if player has power
local function hasPower(player, powerId)
    if not player.powers then return false end
    for _, power in ipairs(player.powers) do
        if power.id == powerId then return true end
    end
    return false
end

-- Get cards by state
local function getCardsByState(player, state)
    local cards = {}
    for _, card in ipairs(player.cards) do
        if card.state == state then
            table.insert(cards, card)
        end
    end
    return cards
end
```

Used across multiple pipelines. Simple, visible, reusable.

---

## Architecture Evolution Summary

The architecture has evolved from basic pipelines to a robust system:

1. **Single source of truth** - `player.cards[]` with state, not separate arrays
2. **One pipeline per mechanic** - GetCost, AcquireCard, ApplyPower, StartTurn, Exhaust
3. **Tags pattern** - Consistent across pipelines (DealDamage, AcquireCard, Exhaust)
4. **On-demand properties** - Add when needed, clear globally
5. **Priority systems** - Pipelines handle precedence (GetCost priority order)
6. **Preserve reference data** - Temporary overrides, not mutations
7. **Early architectural decisions** - Establish patterns immediately
8. **Extensibility** - Each pipeline ready for future interactions

**Core Principle**: Never manipulate game state directly. Always use pipelines.

This keeps the codebase **visible**, **maintainable**, and **extensible** as we add 350+ cards and 100+ powers.
