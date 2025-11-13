# The Centralized Pipeline Architecture Philosophy
## For Game Design: Visibility Over Abstraction

### Core Thesis

**Games are actually small and easy to make if we stop torturing ourselves with unnecessary abstraction.**

Most game systems can be implemented with radical simplicity: centralized pipelines with hardcoded logic, where complexity lives in one visible place rather than scattered across dozens of abstract classes. This approach is **extensible through visibility and simplicity**, not through modularity and design patterns.

---

## The Traditional Approach (And Why It's Torture)

### What We're Taught

When building a game like Slay the Spire or Desktop Dungeons, traditional wisdom says:
- You NEED sophisticated architecture
- Every card should be its own class with polymorphic behavior
- Use inheritance hierarchies and design patterns
- Build abstraction layers for future flexibility
- Follow SOLID principles religiously
- "Open/Closed Principle" - extend without modifying existing code

### The Reality

For a game with 300 cards and 50 status effects:
- **Traditional approach**: 300 card classes + 50 effect classes = scattered logic across 350+ files
- **Actual complexity needed**: ~5,000 lines of explicit code in one place

The torture comes from:
- Fighting imaginary scale problems
- Obsessing over "what if we need 1000 more cards?"
- Building abstraction layers for flexibility you'll never need
- Spending weeks architecting what could be done in days

---

## The Centralized Pipeline Philosophy

### Core Principles

#### 1. One Pipeline Per Game Verb

Each game action gets **one explicit pipeline function**. All logic for that verb lives in one place.

```
DealAttackDamage(attacker, defender, baseDamage, card)
ApplyStatusEffect(target, effectType, amount, card) 
//note: separate status effects application could deserve to be put in different verbs, based on your design
PickItem(player, item)
CastSpell(caster, spell, target)
```

**Not** split into helpers like `GetItemSize()`, `CheckSpace()`, `AddItem()` - that's over-abstracting.

#### 2. Hardcode Special Cases Directly

No polymorphism. No strategy patterns. Just **if-statements checking flags and IDs**.

```javascript
DealAttackDamage(attacker, defender, card) {
    damage = card.baseDamage
    
    // Hardcode Strength directly
    multiplier = card.strengthMultiplier ?? 1  // Default to 1 if not specified
    //if we need to account for relics affecting Strength do it here
    damage += attacker.strength * multiplier
    
    if (defender.has(Vulnerable)) {
        damage *= 1.5
    }
    
    if (attacker.has(Weak)) {
        damage *= 0.75
    }
    
    if (defender.has(Intangible)) {
        damage = 1
    }
    
    defender.hp -= damage
}
```

**50 status effects = 50 if-statements in one visible function.**

#### 3. Cards Are Mostly Just Data

95% of cards are pure data structures:

```javascript
Strike = { id: "Strike", damage: 6, cost: 1, type: ATTACK }
Defend = { id: "Defend", block: 5, cost: 1, type: SKILL }
HeavyBlade = { id: "Heavy_Blade", damage: 14, cost: 2, type: ATTACK, strengthMultiplier: 3 }
```

Only special cards need more.

#### 4. Delta Functions When Needed (But Keep Them Visible)

Some cards need to compute values or inject custom logic:

```javascript
PerfectedStrike = {
    id: "Perfected_Strike",
    cost: 2,
    type: ATTACK,
    baseDamage: (state) => {
        const strikes = state.deck.filter(card => card.tags.includes("Strike")).length
        return 6 + strikes * 2
    }
}

Catalyst = {
    id: "Catalyst",
    cost: 1,
    type: SKILL,
    onResolve: (caster, target, pipelineState, card) => {
        // Mutating function - but visible and localized
        const poison = target.status.poison ?? 0
        const multiplier = card.hasUpgrade ? 3 : 2
        target.status.poison = poison * multiplier
        pipelineState.log.push(`Catalyst set poison on ${target.id} to ${target.status.poison}`)
    }
}
```

IMPORTANT: When you write a mutating delta like `onResolve`, you accept that it runs outside the safety rails of the pipeline—so keep it tiny and obvious.

**Pragmatism over purity**: Let delta functions mutate if that's the simplest expression. The key is **awareness and visibility** - you can Ctrl+F and find every mutation in seconds.

#### 5. Isolated Functions Over Shared Abstractions

For 50 status effects, if you design has genuinely different handling of them, you COULD write 50 separate pipeline functions:

```javascript
ApplyPoison(target, source, tag, amount, card) { 
    if (target.has(ANTIDOTE) && !tag.ignoreAntidote) {
        return
    }

    const prior = target.status.poison ?? 0
    target.status.poison = prior + amount
    effectQueue.push({ type: ON_POISON_GAIN, target, source, amount })
}

ApplyVulnerable(target, source, tag, amount, card) { 
    const cap = target.has(ARTIFACT) ? 1 : amount
    target.status.vulnerable = Math.min(target.status.vulnerable + cap, MAX_VULNERABLE)
    target.combatLog.push(`${target.id} is vulnerable for ${target.status.vulnerable} turns`)
}

ApplyStrength(target, source, tag, amount, card) {
    target.strength += amount
    effectQueue.push({ type: ON_STRENGTH_GAIN, target, source, amount })
    if (target.strength < 0) {
        target.strength = 0
    }
}
```

**Note:** The wildly different rules in the `ApplyX` examples are there to showcase how explicit pipelines can diverge. Your own effects can (and probably should) be calmer. Keep them straightforward unless the design truly needs the chaos.

**Why this works now**: AI makes refactoring trivial. Need to add artifact checking to all 50? "AI, add this check to every ApplyX function" - done in 30 seconds.

The cost of duplication is near-zero. The potential benefit of **complete isolation and clarity** might be massive, depending on your design. 

**One more note:**
We are doing it for efficiency, not for the sake of being edgy/play against rules. If you have TRULY common logic, consider to make a wrapper pipeline, or other form of behaviour standardization.

Please, make an educated call yourself, and DON'T overuse either way.

---

## Extensibility Through Visibility

### The False Promise of Modularity

**Traditional "modular" systems promise**:
- "You can extend without modifying existing code!"
- Open/Closed Principle as gospel

**Reality**:
- You need to understand abstract interfaces, plugin architectures, dependency injection
- The "extensibility" becomes a **barrier to entry**
- Logic is hidden behind polymorphism - you can't see the full picture

### True Extensibility: Make Everything Visible

**Your approach**:
- Want a new effect? Open `CombatPipelines.cs` and add `ApplyMyNewEffect()` - done
- Want a new card interaction? Add one if-statement or data flag - done  
- Everything is **visible and obvious where to extend**

You're not modular - everything's in one place - **but that's the point**.

When you can see all 50 effects, understand the patterns, and add #51 in 5 minutes, you've achieved true extensibility.

**The principle**: Extensibility comes from visibility and simplicity, not modularity. You don't need abstraction layers to be extensible. You need clarity.

---

## Real Examples

### Slay the Spire: Heavy Blade vs Perfected Strike

**Heavy Blade** - "Deal damage. Strength affects this card 3 times."
- **Implementation**: Pure data flag
- `{ strengthMultiplier: 3 }`
- Pipeline reads this flag and multiplies accordingly

**Perfected Strike** - "Deal damage. Damage increases for each Strike in your deck."
- **Implementation**: Read-only delta function
- `{ computeDamage: (state) => 6 + CountStrikesInDeck(state) * 2 }`
- Injects custom logic but doesn't mutate

**Catalyst** - "Double (Triple) target's Poison."
- **Implementation**: Mutating delta function
- `onResolve` reads current poison, multiplies it, and logs the mutation
- Pragmatic - mutation is visible and localized

### Desktop Dungeons: Class-Dependent Item Behavior

**The Wizard Class** - "All glyphs are small items instead of large."

**Don't split it into helpers**:
```javascript
// ❌ OVER-ABSTRACTED
GetItemSize(item, player)
CheckInventorySpace(player, size)
AddToInventory(player, item, size)
```

**Just one pipeline**:
```javascript
// ✅ CENTRALIZED
PickItemPipeline(player, item) {
    // Hardcode Wizard exception right here
    size = item.baseSize
    
    if (player.class == WIZARD && item.type == GLYPH) {
        size = SMALL
    }
    
    // Continue with the action
    if (!player.inventory.hasSpace(size)) {
        return FAIL
    }
    
    player.inventory.add(item, size)
    return SUCCESS
}
```

The whole verb - determining size, checking space, adding item - is **one atomic, visible pipeline**. The Wizard special case is hardcoded right there in the middle.

### Case Study: The Mirror Effect

**What happened:**  
Someone suggested: "Add a mirror effect that reflects attacks."

**Designer:** "Make a mirror that reflects damage back."

**Programmer:** "What exactly does that mean? Step by step."

**Designer:** "It... reflects attacks?"

**Programmer:** "That's flavor text. When someone attacks a mirrored target, what happens? Before or after armor? Does it use attacker's Strength? Does reflected damage trigger Vulnerable? Does it reflect status effects too?"

**Designer:** *(forced to think precisely)* "Oh... just swap the caster and target before resolving the card."

**Implementation:**
```javascript
OnCardCasted(caster, target, card) {
    if (target.has(MIRROR)) {
        swap(caster, target)
    }
    // Continue with normal resolution
}
```

One check. Done.

**The lesson**  
"Mirror effect" sounded vague. Forcing precise definition revealed it's just: swap two variables.

***Important note**
Mirror could be implemented WAY more complex. In fact, there are few dozens of ways to do it, and one showcased in this example isn't perfect. But it's designer job to define what exactly he wants.

**Vague design → forced precision → trivial implementation**

The "inflexibility" of hardcoding forces designers to finish their design work before coding begins.

---

## Scale Arguments Demolished

### "But what about 300 cards?"

**With traditional OOP**:
- 300 cards = 300 classes
- Boilerplate, inheritance, interface methods
- Scattered logic across the codebase
- **Actual complexity**

**With centralized pipelines**:
- 280 cards = pure data (one afternoon with AI)
- 15 cards = read-only functions (one evening)
- 5 cards = mutating functions (clearly marked)
- **Reproducible in one evening with AI**

Complexity grows **linearly** instead of **combinatorially**.

### "But what about 50 effects?"

**50 isolated pipeline functions = ~2,500 lines of explicit, boring code.**

That's not scary. That's **readable**. You can understand the entire combat system in an afternoon.

Compare to: 50 classes with polymorphic dispatch, event systems, observer patterns, scattered across 50 files. Which is actually more complex?

---

## How Extension Actually Works

You don't design 300 cards upfront. That's still the old mindset.

**The actual workflow:**
1. Build core pipelines with 20 basic cards
2. Playtest
3. "I want a card that doubles poison"
4. Add it (2 minutes)
5. Playtest immediately
6. Repeat 280 more times

**Cards 1-50**: Finding core mechanics  
**Cards 51-200**: Exploring the design space  
**Cards 201-300**: Filling out the game

Each card takes minutes to add because there's no abstraction tax. No "does this fit my architecture?" question.

The speed advantage isn't just implementation - it's enabling **rapid design iteration**. No architecture fighting you when you have a new idea.

---

## The AI Era Changes Everything

### Old Fear

"But duplication! What if we need to change something in all 50 places?"

### New Reality

**AI makes that fear obsolete.**

- "AI, add artifact checking to all ApplyX functions" → 30 seconds
- "AI, refactor the accumulation logic in these 15 functions" → trivial
- "AI, generate 50 more cards following this pattern" → one evening

The cost of duplication is near-zero. The benefit of **isolation and clarity** is massive.

**We're not fighting DRY** (Don't Repeat Yourself). We're recognizing that **AI fundamentally changed the cost/benefit of abstraction**.

50 explicit, boring, isolated functions >>> 1 clever, abstract, unified system that's hard to reason about.

---

## Moddability Through Simplicity

### Is This Approach Moddable?

**Yes - potentially MORE moddable than "proper" OOP.**

**For basic mods** (90% of mods):
- Drop in new card data: `{ id: "FireStrike", damage: 10, applyBurn: 2 }`
- No code compilation needed

**For intermediate mods**:
- Delta functions as scripts/lambdas
- `damageBonus: "CountCardsWhere(c => c.cost == 0)"`
- Modders write simple expressions, not full classes

**For advanced mods**:
- The central pipeline is **ONE file to read and understand**
- vs. traditional architecture where logic is scattered across 50 class files
- Much easier to see: "I need to add my mechanic here in DealAttackDamage() between Vulnerable and Intangible"

**The "proper" OOP approach claims extensibility but**:
- Requires understanding complex inheritance hierarchies
- Often needs recompilation
- Breaking changes cascade through abstractions  
- Opaque - can't see the full picture

**Your approach**: "Here's the 500-line pipeline. Here's the card data format. Go wild."

**Simplicity IS moddability.**

---

## When To Use This Architecture

### Perfect For

- **Card games** (Slay the Spire, Monster Train, Inscryption)
- **Roguelikes** (Desktop Dungeons, Into the Breach)
- **Turn-based tactics** (XCOM-likes)
- **Tower defense** with ability interactions
- **Auto-battlers** (Teamfight Tactics, Super Auto Pets)

Basically: **Games with discrete actions, state-based effects, and combinatorial interactions.**

### Characteristics That Benefit

- Dozens of interacting effects/abilities/cards
- Each action has clear begin/middle/end states
- Effects modify core game verbs (attack, defend, move, etc.)
- You need to understand the FULL interaction chain
- Moddability is important

### When NOT To Use

- Real-time action games with continuous physics
- Systems where effects truly need runtime composition
- When you genuinely have 10,000+ cards (you don't)

---

## Implementation Guidelines

### Start With Verbs

List every player action:
- Deal damage
- Take damage  
- Apply status effect
- Remove status effect
- Draw card
- Play card
- Pick up item
- Cast spell
- Move character

**Each verb becomes ONE pipeline function.**

### Build Each Pipeline

For each major verb, player-driven or systemic, write the complete flow in one function:

```javascript
PlayCard(player, card, target) {

    // 0. Special cases handler (opening) 

    // 1. Pay cost (separate pipeline OR here, depending on your project needs)
    
    // 2.a Add card effects to the queue (separate pipeline)
    // 2.b Resolve queue (separate pipeline)

    // 3. Special cases handler (closing)
    
    // 4. Discard
    if (!CardStaysInYourHandAfterBeingPlayed())
    {
        player.hand.remove(card)
    }
    
    if(CardIsExhaustedAfterBeingPlayed())
    {
        //whatever happens on exhausted, if anything, maybe you have relic to trigger right now
    }
    else
    {
        player.discardPile.add(card)
    }

    // 5. Whatever you want, really
}
```

Minor verbs could be either incapsulated or hardcoded as face value, based on your style preference.
It doesn't take away your architecture decisions - you still have to organize pipelines to support your desired logic.

### Keep Data Simple

Most game entities are just data:

```javascript
cards = [
    { id: "Strike", damage: 6, cost: 1 },
    { id: "Defend", block: 5, cost: 1 },
    { id: "Bash", damage: 8, applyVulnerable: 2, cost: 2 }
]

monsters = [
    { id: "Goblin", hp: 12, attack: 6 },
    { id: "Slime", hp: 20, attack: 3, splitOnDeath: true }
]
```

### Add Complexity Only When Needed

When data isn't enough:

```javascript
// Read-only computation
card.damage = (state) => {
    const strikes = state.deck.filter(c => c.tags.includes("Strike")).length
    return 6 + strikes * 2
}

// Mutating behavior (marked clearly so you always could find cards doing something weird)
card.onPlay = (caster, target, pipelineState) => {
    const stolenBlock = Math.min(target.status.block ?? 0, 5)
    target.status.block -= stolenBlock
    caster.status.block = (caster.status.block ?? 0) + stolenBlock
    pipelineState.log.push(`Fluid Barrier stole ${stolenBlock} block for ${caster.id}`)
}
```

### Document Special Cases

At the top of each pipeline, list special behaviors:

```javascript
/**
 * DealAttackDamage Pipeline
 * 
 * Special card behaviors:
 * - Heavy Blade: Strength multiplied 3x
 * - Perfected Strike: +damage per Strike in deck
 * - Bludgeon: Ignores Weak
 * 
 * Status effects applied:
 * - Strength/Dexterity (attacker)
 * - Vulnerable/Weak (defender)
 * - Intangible (defender)
 * - Block (defender)
 */
function DealAttackDamage(attacker, defender, card) {
    let damage = card.baseDamage
    damage += attacker.strength * (card.strengthMultiplier ?? 1)

    if (attacker.status.weak > 0 && !card.ignoreWeak) {
        damage = Math.floor(damage * 0.75)
    }

    if (defender.status.vulnerable > 0) {
        damage = Math.floor(damage * 1.5)
    }

    if (defender.status.intangible > 0) {
        damage = Math.min(damage, 1)
    }

    const remainingBlock = Math.max(defender.status.block - damage, 0)
    const unblockedDamage = damage - (defender.status.block - remainingBlock)
    defender.status.block = remainingBlock
    defender.hp -= unblockedDamage
    combatLog.push(`${attacker.id} dealt ${unblockedDamage} to ${defender.id}`)
}
```

### Let AI Handle Tedium

- "Generate 50 cards following this pattern"
- "Add this check to all Apply functions"  
- "Refactor the mana cost calculation across all spells"

With centralized pipelines, AI can see the full context and make accurate changes.

### Handling Complex Effect Chains: The Queue Pattern

**The Problem:**  
What if effects trigger other effects?

- "Whenever you gain Strength, gain 1 Poison"
- "Whenever you gain Poison, draw a card"  
- Card that gives Strength → triggers Poison → triggers Draw

**The Solution: Effect Queue**

```javascript
const effectQueue = []

ApplyStrength(target, amount, source) {
    target.strength += amount
    
    // Add event to queue for downstream subscribers
    effectQueue.push({ 
        type: ON_STRENGTH_GAIN, 
        target,
        source,
        amount,
        controller: target.controller
    })
}

ProcessEventQueue() {
    while (effectQueue.length > 0) {
        const event = effectQueue.shift()
        
        switch (event.type) {
            case ON_STRENGTH_GAIN:
                if (event.target.has(STRENGTH_TO_POISON_RELIC)) {
                    ApplyPoison(event.target, event.source, {}, 1, null)
                }
                break
            case ON_POISON_GAIN:
                if (event.controller.has(POISON_DRAW_RELIC)) {
                    DrawCard(event.controller, 1)
                }
                break
            default:
                break
        }
    }
}
```

**Critical Warnings:**

**This is cross-pipeline interaction** - your most fragile point.

- Design the queue processing **extremely clearly**
- Document the resolution order explicitly  
- This is where bugs hide if you're not careful
- Test nested triggers thoroughly

**Important:** Not every game needs a queue! If your effects don't trigger other effects, don't build one. Add it only when your design requires nested triggers.

The queue is complexity you accept when your game design demands it. Not default architecture.

### Organizing Special Cases

For the 5-10 cards that need custom functions (like Catalyst), keep them organized:

**Options:**
- Registry in code: `SpecialCards = { CATALYST: (caster, target) => target.status.poison *= 2, MIRROR: swapCasterTarget }`
- Separate files: `catalyst_special.json` or `cards_special/*.json`
- Mark in data: `{ id: "Catalyst", hasSpecialBehavior: true }`

**The point:** Make it obvious where the weird stuff lives. Anyone reading your code should immediately see "here are the 5 cards that do non-standard things."

This isn't a design pattern - it's just organization. Keep your exceptions visible and together.

---

## The Philosophy In One Paragraph

**Build games with radical simplicity. Centralize all game logic in explicit pipelines - one per game verb. Hardcode special cases directly with if-statements. Make cards/items/effects mostly pure data, with occasional delta functions. Embrace 50 isolated functions over 1 abstract system. Let AI handle refactoring and duplication. Stop architecting for imaginary scale problems. Extensibility comes from visibility and simplicity, not modularity. Most games are small - we just make them complicated with unnecessary abstraction.**

---

## Why This Matters

You're not sacrificing anything by rejecting traditional OOP patterns:
- ✅ Still extensible (more so, because visible)
- ✅ Still maintainable (more so, because simple)
- ✅ Still moddable (more so, because obvious, it just makes a bit harder to merge mods)
- ✅ Actually shippable (much faster to build)

You're gaining:
- **Visibility** - see the entire system at once
- **Simplicity** - no hidden behavior, no surprises
- **Speed** - build in days what "proper" architecture takes weeks
- **Clarity** - anyone can understand and modify your code

**Actual games are small.** A complete Slay the Spire combat system is ~5,000 lines. Desktop Dungeons with all its systems is maybe 10,000 lines. 

**We torture ourselves** by trying to architect these small systems like we're building enterprise software.

**Stop. Just hardcode it. Make it visible. Ship your game.**

---

## Final Thoughts

This isn't about being sloppy or unprofessional. It's about **being pragmatic**.

"Proper" software architecture evolved for problems like:
- Operating systems
- Databases  
- Enterprise applications with 100+ developers
- Systems that need to run for decades

**Your game is not that.**

Your game has:
- 5 to 30 verbs
- 300 to 1000 cards
- 50 to 250 effects 
- 5,000 to 15,000 lines of game logic
- You as a solo dev
- A 2-year lifecycle

**Match your architecture to your actual problem.**

The centralized pipeline approach isn't a hack. It's **choosing the right tool for the job**: visibility, simplicity, and velocity over imaginary flexibility.

Build games. Not architecture.
