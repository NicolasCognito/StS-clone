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
