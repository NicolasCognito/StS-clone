# Implementation Guidelines - Decision-Making Framework

**Last Updated:** 2025-11-13

This document provides a **practical decision-making framework** for implementing new game content (cards, enemies, relics, mechanics) in the Slay the Spire clone. It's designed for AI agents and developers to systematically analyze requirements and choose appropriate implementation strategies.

---

## Decision-Making Process (The 6-Step Framework)

When implementing ANY new content, follow this systematic process:

### Step 0: Understand the Architecture
**Action:** Read `PROJECT_MAP.md` to understand:
- Dual queue system (EventQueue FIFO, CardQueue LIFO)
- Pipeline architecture (centralized game logic)
- World state structure (masterDeck vs combatDeck, hp vs currentHp)
- Context system (stable vs temp)
- Combat flow (StartTurn → Player Actions → EndTurn → Enemy Turns → EndRound)
- Map vs Combat separation

**Key Questions:**
- Where does my mechanic fit in the game loop?
- What existing systems does it interact with?
- Is it combat-only, map-only, or both?

---

### Step 1: Determine Pipeline Requirements

**Decision Tree:**

```
Does this mechanic need to interact with existing game systems?
├─ YES → Use existing pipelines via event queue
│   ├─ Damage? → ON_DAMAGE (attack) or ON_NON_ATTACK_DAMAGE (HP loss)
│   ├─ Block? → ON_BLOCK
│   ├─ Status effects? → ON_STATUS_GAIN
│   ├─ Card manipulation? → ON_DRAW, ON_DISCARD, ON_EXHAUST, ON_ACQUIRE_CARD
│   ├─ Healing? → ON_HEAL
│   ├─ Complex logic? → ON_CUSTOM_EFFECT
│   └─ Target selection? → COLLECT_CONTEXT
│
└─ NO → Consider direct state modification
    ├─ Very simple (energy gain, flag setting)? → Direct modification
    ├─ Needs logging/hooks? → Use ON_CUSTOM_EFFECT wrapper
    └─ Uncertain? → Default to ON_CUSTOM_EFFECT (safer)
```

**Examples:**

**Simple Attack (Strike):**
- Needs: Damage pipeline
- Solution: Push `ON_DAMAGE` event
- Context: Requires enemy target (stable)

**Energy Manipulation (Offering):**
- Needs: Energy gain, HP loss, card draw
- Solution: Direct energy modification + `ON_NON_ATTACK_DAMAGE` + `ON_DRAW`
- Why mixed: Energy has no hooks elsewhere, but HP loss and draw do

**Complex Effect (Catalyst):**
- Needs: Double poison on target
- Solution: `ON_CUSTOM_EFFECT` wrapper with direct status modification
- Why: Poison multiplication has no hooks, too niche for pipeline

**Direct Modification Example (Judgment - rarity check):**
- Needs: Check if only one enemy, deal damage equal to its HP
- Solution: `ON_CUSTOM_EFFECT` wrapping direct state check + `ON_DAMAGE`
- Why: Rarity check is card-specific, but damage uses pipeline for modifiers

---

### Step 2: Determine if New Pipeline is Needed

**When to Create New Pipeline:**

✅ **CREATE when:**
1. **High reuse potential** - Multiple cards/relics/enemies will use it
2. **Complex interactions** - Needs to check multiple modifiers (powers, relics, status)
3. **Needs hooks** - Other systems need to react to this event
4. **State consistency critical** - Must maintain invariants (caps, death checks)

❌ **DON'T CREATE when:**
1. **One-off mechanic** - Used by 1-2 cards only
2. **No modifiers** - Direct state change with no interactions
3. **Can compose from existing** - Combining existing pipelines works fine

**Decision Matrix:**

| Mechanic | Reuse? | Interactions? | Hooks? | Decision | Reasoning |
|----------|--------|---------------|--------|----------|-----------|
| Auto-play card | Medium | High | Yes | **Create PlayCard.autoExecute()** | Multiple cards use it (Havoc, Omniscience), needs context handling |
| Stance system | High | Medium | Yes | **Create ChangeStance.lua** | Multiple cards change stance, needs exit/enter hooks |
| Map damage | Medium | Low | Maybe | **Create Map_ReceiveDamage.lua** | Cleaner separation, map events need consistent damage handling |
| Poison doubling | Low | Low | No | **Use ON_CUSTOM_EFFECT** | Only Catalyst, simple status manipulation |
| Slime splitting | Low | Low | No | **Direct in enemy intent** | Boss-specific, self-contained logic |

**Real Examples:**

**CREATED: PlayCard.autoExecute()** (for Havoc, Omniscience)
- **Why:** Multiple cards play other cards, needs:
  - Context collection handling
  - State management (card.state, _previousState)
  - Energy override for free plays
  - Forced replay queueing (Omniscience plays twice)
- **Impact:** PlayCard pipeline gained helper function, no new pipeline file

**CREATED: ChangeStance.lua** (for Watcher)
- **Why:** Stance switching needs:
  - Exit current stance (Calm gives energy, Wrath resets)
  - Enter new stance (stat modifiers)
  - Multiple cards change stances
  - Potential relic hooks
- **Impact:** New pipeline, called via event queue

**CREATED: Map_ReceiveDamage.lua** (for map events)
- **Why:** Map events cause HP loss:
  - Consistent with combat damage patterns
  - Potential relic hooks (e.g., damage reduction relics)
  - Cleaner than direct HP mutation in events
- **Impact:** New map pipeline, mirrors combat patterns

**SEPARATED: DealNonAttackDamage.lua** (from DealDamage.lua)
- **Why:** Attack damage vs HP loss have VERY different rules:
  - Attack damage: affected by Strength, Vulnerable, Weak
  - HP loss: NOT affected by combat modifiers, can ignore block
  - Conforming both to one pipeline was impractical
- **Impact:** Split into two pipelines with different modifier chains

**NOT CREATED: Poison Doubling** (Catalyst card)
- **Why:** Only one card uses it, simple status multiplication
- **Solution:** `ON_CUSTOM_EFFECT` with direct `enemy.status.poison = enemy.status.poison * 2`
- **Impact:** No new pipeline needed

**NOT CREATED: Slime Boss Splitting** (Slime Boss enemy)
- **Why:** Boss-specific mechanic, self-contained
- **Solution:** Logic in `enemy.intents.split()` and `ChangeIntentOnDamage()`
- **Impact:** No new system, just enemy implementation

---

### Step 3: Determine if New Queue is Needed

**When to Create New Queue:**

✅ **CREATE when:**
1. **Execution order CANNOT be handled by existing queues**
2. **Separate lifecycle** - Needs independent processing from event flow
3. **Stack vs Queue semantics required** - LIFO vs FIFO matters critically

❌ **ALMOST NEVER CREATE** - Queues add significant complexity

**Decision Matrix:**

| Problem | Existing Solution | New Queue? | Reasoning |
|---------|-------------------|------------|-----------|
| Card duplication stacking | CardQueue (LIFO) | ✅ **CREATED** | Events can't handle "play later" semantics, LIFO critical for correct order |
| Priority events (context, death) | EventQueue with "FIRST" strategy | ❌ No | Priority insertion solves it |
| Map event actions | mapQueue (EventQueue instance) | ✅ **CREATED** | Separate lifecycle from combat, same pattern |
| Delayed effects (e.g., "at end of turn") | Event queue at EndTurn | ❌ No | Temporal hooks in pipelines work |
| Relic triggers | Direct calls in pipelines | ❌ No | Synchronous hooks sufficient |

**Real Example: CardQueue Creation (Card Duplication)**

**Problem:**
- Double Tap: "Your next Attack is played twice"
- Burst: "Your next Skill is played twice"
- Echo Form: "The first card you play each turn is played twice"
- Necronomicon: "The first Attack costing 2+ each turn is played twice"

**Why Event Queue Can't Handle It:**

```
Naive approach (using only EventQueue):
1. Card.onPlay() pushes damage events
2. Try to duplicate by pushing same events again?
   ❌ Problem: onPlay() already ran, can't re-run
   ❌ Problem: Context already collected, duplicates must reuse
   ❌ Problem: Need to mark "this is a duplicate" for logging
   ❌ Problem: Only last duplicate should discard card
```

**Solution: CardQueue (LIFO Stack)**

```
CardQueue approach:
1. PlayCard.execute() builds duplication plan
2. Push entries to stack: [Initial, Dupe1, Dupe2]
3. Pop and execute in REVERSE: Dupe2 → Dupe1 → Initial
   ✅ Each entry calls card.onPlay() fresh
   ✅ Stable context persists, temp context re-collected
   ✅ Metadata tracks: isInitial, isLast, replaySource
   ✅ Only isLast=true triggers discard
```

**LIFO Critical:**
- Push order (bottom→top): Initial, Double Tap copy, Echo Form copy
- Pop order (top→bottom): Echo Form copy, Double Tap copy, Initial
- Creates visual: Initial effect → Double Tap → Echo Form (correct!)

**Impact:** Major architecture addition, but solved previously unsolvable problem

**Real Example: MapQueue Creation (Map Events)**

**Problem:**
- Map events need action sequencing (heal, remove card, gain relic)
- Combat queue is nil outside combat
- Map actions have different lifecycle than combat events

**Solution: mapQueue (EventQueue instance for map context)**

```lua
world.mapQueue = EventQueue.new()  -- Separate queue for map
```

**Why Separate Queue:**
- Map events run outside combat (no world.queue)
- Similar patterns (FIFO, push/pop, drain-and-process)
- Independent lifecycle (map event complete ≠ combat end)

**Impact:** Minor addition (reused EventQueue class), big clarity gain

---

### Step 4: Determine Engine/World Modifications

**When to Modify Core Systems:**

#### A. Engine Modifications (CombatEngine, MapEngine, Queues)

**Modify CombatEngine when:**
- **Special turn flow** - Mechanic hijacks normal turn cycle (Vault)
- **Handler pattern change** - New type of user interaction
- **Win/lose condition** - New game-ending states

**Modify Queue/Context System when:**
- **New insertion strategy** - Need different priority (e.g., "FIRST" for death/context)
- **New context type** - Beyond stable/temp (unlikely)
- **Validation requirements** - Context must meet new criteria

**Examples:**

**MODIFIED: EventQueue.push() Strategy** (for Death priority)
```lua
-- Problem: Death events must process IMMEDIATELY (before other events)
-- Solution: Added "FIRST" strategy to push to front of queue

world.queue:push({type = "ON_DEATH", ...}, "FIRST")  -- Jump to front
```

**Why:** Death checks must happen before subsequent events (e.g., multi-enemy AOE kills one, others take damage, dead enemy shouldn't act)

**Impact:** EventQueue.lua gained strategy parameter, ProcessEventQueue unchanged

**MODIFIED: CombatEngine.playGame()** (for Vault special handling)
```lua
-- Problem: Vault skips enemy turns AND EndRound
-- Solution: Check world.combat.vaultPlayed flag after EndTurn

if world.combat.vaultPlayed then
    -- Skip enemy turns
    -- Skip EndRound
    StartTurn.execute(world, player)  -- Go straight to new turn
    world.combat.vaultPlayed = nil
end
```

**Why:** Vault's "skip enemies' turn" can't be expressed via queue events (it's turn flow hijacking)

**Impact:** CombatEngine gained special case, Vault card sets flag

**MODIFIED: ContextProvider** (for Scry)
```lua
-- Problem: Scry shows top N cards, player discards some
-- Solution: Added 'scry' field to contextProvider

contextProvider = {
    type = "cards",
    scry = 3,  -- Show top 3 cards from deck
    count = {min = 0, max = 3}  -- Can discard 0-3
}
```

**Why:** Scry has unique selection semantics (view deck top, selective discard)

**Impact:** ContextProvider.lua gained scry handling, Scry.lua pipeline created

#### B. World Modifications

**Modify World when:**
- **New persistent state** - Cross-combat/cross-map data (relics, deck, gold)
- **New transient state** - Combat-only or map-only state
- **New resource** - Player capability (energy, card draw, potions)

**Examples:**

**ADDED: world.player.orbs** (for Defect)
```lua
world.player.orbs = {}      -- Array of orb instances
world.player.maxOrbs = 3    -- Orb slots
```

**Why:** Orbs persist across turns but reset across combats (combat-persistent)

**Impact:** World.lua gained orb fields, orb pipelines created

**ADDED: world.player.currentStance** (for Watcher)
```lua
world.player.currentStance = nil  -- "Calm", "Wrath", "Divinity", or nil
```

**Why:** Stance persists across turns, affects damage/block calculations

**Impact:** World.lua gained stance field, ChangeStance pipeline created, DealDamage/ApplyBlock check stance

**ADDED: world.combat.vaultPlayed** (for Vault card)
```lua
world.combat.vaultPlayed = nil  -- Flag set by Vault card
```

**Why:** Vault needs to communicate with CombatEngine turn flow

**Impact:** Combat context gained flag, CombatEngine checks it

**ADDED: world.penNibCounter, world.wingedBootsCharges** (for relics)
```lua
-- Persistent relic state
world.penNibCounter = 0
world.wingedBootsCharges = 3
```

**Why:** Relics track state across combats (can't live in player.status)

**Impact:** World.lua gained relic state fields, pipelines check them

**NOT ADDED: Catalyst poison doubling**
- **Why:** One-off card effect, no persistent state needed
- **Solution:** Direct manipulation in ON_CUSTOM_EFFECT

**NOT ADDED: Slime splitting**
- **Why:** Boss-specific, state tracked in enemy instance (self.hasSplit)
- **Solution:** Enemy tracks own state, no world modification

---

### Step 5: Outline Modifications and Provide Plan

**Format:**

```
# Implementation Plan: [Mechanic Name]

## Overview
[1-2 sentence description of what we're implementing]

## Analysis
- **Complexity:** Low/Medium/High
- **Scope:** Card-only / Enemy-only / System-wide
- **Reuse:** One-off / Multiple uses / Foundational

## Decisions
1. **Pipelines:** [Which existing pipelines needed? Any new ones?]
2. **Queues:** [Use existing? Create new? Why?]
3. **Engine Changes:** [Any? Where and why?]
4. **World Changes:** [Any new state? Where does it live?]

## Implementation Steps
1. [Step 1 with file path and key changes]
2. [Step 2 with file path and key changes]
3. [...]

## Testing Strategy
- [What to test]
- [Expected behavior]
- [Edge cases]

## Documentation Updates
- [ ] Update PROJECT_MAP.md if new pipeline/system added
- [ ] Add example to GUIDELINE.md if novel pattern
- [ ] Update ARCHITECTURE_NOTES.md if trade-off involved
```

**Examples below in Step 6**

---

### Step 6: Implement and Update Documentation

**Implementation Checklist:**

- [ ] Create new files (cards, enemies, pipelines)
- [ ] Modify existing pipelines (add hooks, checks)
- [ ] Modify engine/world (if required)
- [ ] Add tests (in `tests/` directory)
- [ ] Test manually (run game, verify behavior)
- [ ] Update `PROJECT_MAP.md` (if new system/pipeline added)
- [ ] Update this file (`GUIDELINE.md`) (if novel pattern)

---

## Decision-Making Examples (Real Content)

Below are **real examples** showing the complete thought process for actual implementations.

---

## Example 1: Slime Boss Splitting (Enemy Mechanic)

### Step 0: Understand Architecture
- **What:** Boss enemy that splits into 2 smaller enemies at 50% HP
- **Where:** Combat only, enemy-specific
- **Interactions:** Death system, enemy array manipulation

### Step 1: Pipeline Requirements
**Analysis:**
- Needs to spawn new enemies → Modify `world.enemies` array
- Needs to remove self → Modify `world.enemies` array
- Needs to trigger at HP threshold → Reactive behavior
- Doesn't need damage/block/status pipelines

**Decision:** Direct implementation in enemy, no pipelines needed

### Step 2: New Pipeline?
**Question:** Should we create `SummonEnemy` pipeline?

**Analysis:**
- **Reuse?** Low - Only boss uses it (maybe future summoners, but uncertain)
- **Interactions?** None - Just array manipulation
- **Hooks?** None - No relics/powers react to summoning (yet)

**Decision:** ❌ **NO new pipeline** - Direct implementation in enemy intent

### Step 3: New Queue?
**Question:** Could splitting be queued as an event?

**Analysis:**
- Event queue could work: `{type = "ON_SPLIT", enemy = self}`
- But: Adds complexity for single use case
- Direct is simpler and clearer

**Decision:** ❌ **NO new queue** - Direct implementation

### Step 4: Engine/World Changes?
**Question:** Does CombatEngine need to know about splitting?

**Analysis:**
- CombatEngine already handles dynamic enemy list (death removes enemies)
- Splitting = remove 1, add 2 (net +1 enemy)
- No special turn flow handling needed
- Win condition checks `hasLivingEnemies()` - works automatically

**Decision:** ❌ **NO engine changes** - Existing systems handle it

**Question:** Does World need split tracking?

**Analysis:**
- Need `self.hasSplit` flag to prevent repeated splits
- This is enemy instance state, not world state

**Decision:** ❌ **NO world changes** - Enemy tracks own state

### Step 5: Implementation Plan

```
# Implementation Plan: Slime Boss Splitting

## Overview
Slime Boss splits into 2 Spike Slimes when HP drops to 50% or below.

## Analysis
- **Complexity:** Low
- **Scope:** Enemy-only (boss-specific mechanic)
- **Reuse:** One-off (future summoners would use different pattern)

## Decisions
1. **Pipelines:** None needed - direct enemy implementation
2. **Queues:** Use existing (enemy intent execution via EventQueue)
3. **Engine Changes:** None - dynamic enemy list already handled
4. **World Changes:** None - enemy tracks own state

## Implementation Steps

1. **Add split intent to Slime Boss** (`Data/Enemies/slime.lua`)
   ```lua
   intents = {
       split = function(self, world, player)
           local Utils = require("utils")
           local Enemies = require("Data.Enemies.slime")

           -- Spawn 2 Spike Slimes
           for i = 1, 2 do
               table.insert(world.enemies, Utils.copyEnemyTemplate(Enemies.SpikeSlime))
           end

           -- Remove self
           for i, enemy in ipairs(world.enemies) do
               if enemy == self then
                   table.remove(world.enemies, i)
                   break
               end
           end

           table.insert(world.log, self.name .. " splits into 2 slimes!")
       end
   }
   ```

2. **Add reactive trigger** (`Data/Enemies/slime.lua`)
   ```lua
   ChangeIntentOnDamage = function(self, world, source)
       if self.hp <= self.maxHp / 2 and not self.hasSplit then
           self.hasSplit = true  -- Prevent repeated splits
           self.currentIntent = {
               name = "Split",
               description = "Split into 2 slimes",
               execute = self.intents.split
           }
       end
   end
   ```

3. **Hook into DealDamage pipeline** (`Pipelines/DealDamage.lua`)
   ```lua
   -- After applying damage, check for reactive triggers
   if defender.ChangeIntentOnDamage then
       defender:ChangeIntentOnDamage(world, attacker)
   end
   ```

## Testing Strategy
- Create boss at 60% HP, deal damage to drop below 50%
- Verify: Boss disappears, 2 Spike Slimes appear
- Verify: Only splits once (hasSplit flag works)
- Verify: Combat doesn't crash with dynamic enemy count

## Documentation Updates
- [ ] Update PROJECT_MAP.md: Document ChangeIntentOnDamage pattern
- [x] Already documented in enemy system section
```

### Step 6: Implementation Result
✅ **Implemented** - No new systems needed, used existing patterns

**Files Modified:**
- `Data/Enemies/slime.lua` - Added split intent and ChangeIntentOnDamage
- `Pipelines/DealDamage.lua` - Added ChangeIntentOnDamage hook call

**Files Created:** None

**Key Insight:** Sometimes the simplest solution is direct implementation, not abstraction.

---

## Example 2: Vault Card (Turn Flow Hijacking)

### Step 0: Understand Architecture
- **What:** Card that ends your turn, skips enemies' turns, starts new player turn
- **Where:** Combat only, special turn flow
- **Interactions:** CombatEngine turn cycle

### Step 1: Pipeline Requirements
**Analysis:**
- Needs to end current turn → EndTurn pipeline
- Needs to skip enemy turns → CAN'T be expressed via pipeline (turn flow!)
- Needs to skip EndRound → CAN'T be expressed via pipeline (turn flow!)
- Needs to start new turn → StartTurn pipeline

**Decision:** Pipelines insufficient, needs engine modification

### Step 2: New Pipeline?
**Question:** Should we create `SkipEnemyTurns` pipeline?

**Analysis:**
- **Turn flow, not game event** - Pipelines handle events, not control flow
- Would still need CombatEngine to cooperate
- No value in abstraction here

**Decision:** ❌ **NO new pipeline** - Engine modification required

### Step 3: New Queue?
**Question:** Could turn skipping be queued?

**Analysis:**
- Queues process during a turn, not between turns
- Turn cycle is handled by CombatEngine loop, not queues
- Queues can't express "skip next N iterations of loop"

**Decision:** ❌ **NO new queue** - Wrong abstraction

### Step 4: Engine/World Changes?
**Question:** How does card communicate with CombatEngine?

**Analysis:**
- Card executes during player turn
- CombatEngine checks win/lose after card play
- Then CombatEngine normally runs enemy turns
- Need: Signal to CombatEngine "skip enemy turns this time"

**Decision:** ✅ **Flag in world.combat**
```lua
world.combat.vaultPlayed = true  -- Vault sets this
```

**Question:** Where does CombatEngine check flag?

**Analysis:**
```
Normal flow:
EndTurn → Check win/lose → Enemy Turns (loop) → EndRound → StartTurn

Vault flow:
EndTurn → Check win/lose → [SKIP ENEMIES] → [SKIP ENDROUND] → StartTurn
```

**Location:** After EndTurn, before enemy turn loop

**Decision:** ✅ **Modify CombatEngine.playGame()** - Add special case for Vault

### Step 5: Implementation Plan

```
# Implementation Plan: Vault Card

## Overview
Vault ends your turn, skips all enemy turns, and starts a new player turn.

## Analysis
- **Complexity:** Medium (requires engine modification)
- **Scope:** Card + CombatEngine interaction
- **Reuse:** One-off (but establishes pattern for turn flow hijacking)

## Decisions
1. **Pipelines:** Use existing EndTurn and StartTurn
2. **Queues:** None - turn flow is outside queue system
3. **Engine Changes:** ✅ CombatEngine special case for Vault flag
4. **World Changes:** ✅ world.combat.vaultPlayed flag

## Implementation Steps

1. **Create Vault card** (`Data/Cards/vault.lua`)
   ```lua
   Vault = {
       id = "Vault",
       name = "Vault",
       cost = 2,
       type = "SKILL",
       description = "End your turn. Skip enemies' turn. Start a new turn.",

       onPlay = function(self, world, player, target)
           world.combat.vaultPlayed = true
           table.insert(world.log, "Vault! Skipping enemies' turn...")
       end
   }
   ```

2. **Modify CombatEngine** (`CombatEngine.lua`)
   ```lua
   -- After EndTurn.execute(world, player)
   if world.combat.vaultPlayed then
       -- Check win/lose (enemies might be dead)
       if not hasLivingEnemies(world) then
           gameOver = true
           -- ... handle victory
       else
           -- Skip enemy turns (don't run loop)
           -- Skip EndRound (don't tick status effects)
           table.insert(world.log, "Enemies' turns skipped (Vault)")

           -- Go straight to new player turn
           StartTurn.execute(world, player)
           world.combat.vaultPlayed = nil  -- Clear flag
       end
   else
       -- Normal flow: enemy turns → EndRound → StartTurn
   end
   ```

3. **Add combat context field** (`Pipelines/StartCombat.lua`)
   ```lua
   world.combat = {
       vaultPlayed = nil,  -- Flag for Vault card
       -- ... other combat state
   }
   ```

## Testing Strategy
- Play Vault mid-combat with enemies alive
- Verify: EndTurn triggers (discard, energy reset)
- Verify: Enemies DO NOT act (intents unchanged)
- Verify: EndRound skipped (status effects don't tick)
- Verify: New player turn starts (draw cards, reset block)
- Edge case: Vault with enemies at different HP (status persistence)

## Documentation Updates
- [x] Update PROJECT_MAP.md: Document Vault special handling
- [x] Add to GUIDELINE.md as example of engine modification
```

### Step 6: Implementation Result
✅ **Implemented** - Required engine modification, established pattern

**Files Modified:**
- `CombatEngine.lua` - Added Vault special case handling
- `Pipelines/StartCombat.lua` - Added vaultPlayed flag to combat context

**Files Created:**
- `Data/Cards/vault.lua` - Vault card implementation

**Key Insight:** Some mechanics can't be expressed via pipelines - they require engine-level cooperation.

---

## Example 3: Echo Form Power (Card Duplication)

### Step 0: Understand Architecture
- **What:** Power that makes first card each turn play twice
- **Where:** Combat only, affects card execution
- **Interactions:** Card play system, turn start

### Step 1: Pipeline Requirements
**Analysis:**
- Needs to duplicate card plays → PlayCard pipeline
- Needs per-turn counter → StartTurn pipeline
- Needs power application → ON_APPLY_POWER event
- Existing pipes sufficient? Let's trace:

```
1. Player plays card
2. PlayCard.execute() checks for duplication sources
3. Need to check: player.status.echoFormThisTurn > 0
4. If yes, add duplication to plan
5. Decrement counter after first card
```

**Decision:** Use existing pipelines (PlayCard, StartTurn), no new pipes needed

### Step 2: New Pipeline?
**Question:** Do we need EchoDuplication pipeline?

**Analysis:**
- PlayCard already handles Double Tap and Burst
- Echo Form follows same pattern (status counter → duplication)
- Difference: Per-turn limit (first N cards) vs per-card type (attacks/skills)

**Decision:** ❌ **NO new pipeline** - Extend existing PlayCard duplication system

### Step 3: New Queue?
**Question:** Is CardQueue sufficient for Echo Form?

**Analysis:**
- CardQueue already handles duplications (LIFO stack)
- Echo Form just adds another duplication source
- Multiple sources can stack: Echo Form + Double Tap = 3 copies (initial + 2 duplications)

**Decision:** ✅ **Use existing CardQueue** - Already designed for this

### Step 4: Engine/World Changes?
**Question:** Where does Echo Form state live?

**Analysis:**
- Power has `stacks` (number of times it applies)
- Need per-turn counter: `echoFormThisTurn` (decrements with each card)
- Per-turn counter resets at start of turn

**Comparison with Double Tap:**
```
Double Tap:
  - player.status.doubleTap = 2  (next 2 attacks)
  - Decremented in PlayCard (after attack plays)

Echo Form:
  - player.powers.EchoForm.stacks = 1  (power stacks)
  - player.status.echoFormThisTurn = 1  (per-turn counter)
  - Counter set in StartTurn (from power stacks)
  - Decremented in PlayCard (after any card plays)
```

**Decision:**
- ✅ Power lives in `player.powers.EchoForm`
- ✅ Per-turn counter lives in `player.status.echoFormThisTurn`

**Question:** Does StartTurn need modification?

**Analysis:**
- StartTurn already resets per-turn flags
- Need to add: Copy power stacks → status counter

**Decision:** ✅ **Modify StartTurn** - Add Echo Form counter reset

**Question:** Does PlayCard need modification?

**Analysis:**
- PlayCard already has duplication system (DuplicationHelpers)
- Need to add Echo Form to duplication plan builder

**Decision:** ✅ **Modify PlayCard duplication system** - Add Echo Form source

### Step 5: Implementation Plan

```
# Implementation Plan: Echo Form Power

## Overview
Echo Form is a power that makes the first card(s) each turn play twice.

## Analysis
- **Complexity:** Medium (integrates with existing duplication system)
- **Scope:** Card (applies power) + Power definition + Pipeline modifications
- **Reuse:** Foundational (duplication system, other powers can use pattern)

## Decisions
1. **Pipelines:** Extend PlayCard (duplication), modify StartTurn (counter reset)
2. **Queues:** Use existing CardQueue (LIFO stack handles it)
3. **Engine Changes:** None
4. **World Changes:**
   - player.powers.EchoForm (power instance)
   - player.status.echoFormThisTurn (per-turn counter)

## Implementation Steps

1. **Create Echo Form power definition** (`Data/Powers/echoform.lua`)
   ```lua
   EchoForm = {
       id = "EchoForm",
       name = "Echo Form",
       stacks = 1,
       description = "The first card you play each turn is played twice."
   }
   ```

2. **Create Echo Form card** (`Data/Cards/echoform.lua`)
   ```lua
   EchoForm = {
       id = "EchoForm",
       cost = 3,
       type = "POWER",
       description = "The first card you play each turn is played twice.",

       onPlay = function(self, world, player)
           local Powers = require("Data.powers")
           world.queue:push({
               type = "ON_APPLY_POWER",
               target = player,
               powerTemplate = Powers.EchoForm
           })
       end
   }
   ```

3. **Modify StartTurn to set counter** (`Pipelines/StartTurn.lua`)
   ```lua
   -- After clearing turn flags
   local Utils = require("utils")
   local echoFormPower = Utils.getPower(player, "EchoForm")
   if echoFormPower then
       player.status = player.status or {}
       player.status.echoFormThisTurn = echoFormPower.stacks
   end
   ```

4. **Modify PlayCard duplication system** (`Pipelines/PlayCard_DuplicationHelpers.lua`)
   ```lua
   function DuplicationHelpers.buildReplayPlan(world, player, card)
       local plan = {}

       -- Check Echo Form (any card, per-turn limit)
       if player.status and player.status.echoFormThisTurn and player.status.echoFormThisTurn > 0 then
           table.insert(plan, "Echo Form")
           player.status.echoFormThisTurn = player.status.echoFormThisTurn - 1
       end

       -- Check Double Tap (attacks only)
       if card.type == "ATTACK" and player.status and player.status.doubleTap and player.status.doubleTap > 0 then
           table.insert(plan, "Double Tap")
           player.status.doubleTap = player.status.doubleTap - 1
       end

       -- ... (other duplication sources)

       return plan
   end
   ```

5. **Add counter decrement** (Already handled in step 4)
   - Counter decremented when duplication plan is built
   - Happens automatically for first card played each turn

## Testing Strategy
- Apply Echo Form power at turn start
- Play first card → should play twice
- Play second card → should play once (counter exhausted)
- Next turn → counter resets, first card plays twice again
- Test stacking: Echo Form + Double Tap → 3 total plays (initial + 2 duplications)
- Test with multi-turn Echo Form (stacks > 1)

## Documentation Updates
- [x] Update PROJECT_MAP.md: Document duplication system
- [x] Add to GUIDELINE.md as example of extending existing system
```

### Step 6: Implementation Result
✅ **Implemented** - Extended existing duplication system, no new architecture

**Files Modified:**
- `Pipelines/StartTurn.lua` - Added Echo Form counter reset
- `Pipelines/PlayCard_DuplicationHelpers.lua` - Added Echo Form to duplication plan

**Files Created:**
- `Data/Powers/echoform.lua` - Power definition
- `Data/Cards/echoform.lua` - Card that applies power

**Key Insight:** Well-designed systems can be extended without creating new architecture. Echo Form fits naturally into existing duplication system.

---

## Example 4: Havoc Card (Auto-Play from Deck)

### Step 0: Understand Architecture
- **What:** Card that plays top card of draw pile for free
- **Where:** Combat only, plays other cards
- **Interactions:** Card play system, deck manipulation

### Step 1: Pipeline Requirements
**Analysis:**
- Needs to play another card → PlayCard pipeline
- That card might need context → Context system
- That card might be X-cost → Need energy override
- That card might have special requirements → Need skip energy cost

**Naive approach:**
```lua
-- WRONG: This won't work
onPlay = function(self, world, player)
    local topCard = getTopCard(player.combatDeck)
    PlayCard.execute(world, player, topCard)  -- Problem: Needs context handling!
end
```

**Problems:**
1. `PlayCard.execute()` is for user-initiated plays (expects context collection)
2. Havoc needs **automatic** play (no user input)
3. X-cost cards need energy override (Havoc plays for free)
4. Need to handle play failure (card unplayable, etc.)

**Decision:** Need specialized `PlayCard.autoExecute()` helper

### Step 2: New Pipeline?
**Question:** Should we create AutoPlayCard pipeline?

**Analysis:**
- **Reuse:** Multiple cards use auto-play (Havoc, Omniscience, Gambit, etc.)
- **Complexity:** High (context collection automation, state management)
- **Interactions:** Integrates tightly with existing PlayCard

**Decision:** ✅ **Create PlayCard.autoExecute() helper** (not separate pipeline, extension of PlayCard)

### Step 3: New Queue?
**Question:** Does auto-play need a queue?

**Analysis:**
- Auto-play happens during current card's execution
- The played card uses existing CardQueue for its own duplications
- No new queue semantics needed

**Decision:** ❌ **NO new queue** - Use existing CardQueue

### Step 4: Engine/World Changes?
**Question:** Does World need auto-play tracking?

**Analysis:**
- No persistent state needed
- Card state management (card.state, _previousState) is temporary
- All state lives in card instances during execution

**Decision:** ❌ **NO world changes** - Temporary state only

**Question:** Does context collection need modification?

**Analysis:**
- Auto-play must collect context automatically (no user prompt)
- Context collection pauses execution, returns {needsContext = true}
- Need: Auto-resume mechanism

**Current context flow:**
```
1. PlayCard.execute() called
2. Card.onPlay() pushes events with lazy context
3. ProcessEventQueue hits COLLECT_CONTEXT
4. Returns {needsContext = true} to CombatEngine
5. CombatEngine prompts user for context
6. PlayCard.execute() resumed
```

**Auto-play context flow:**
```
1. PlayCard.autoExecute() called
2. Card.onPlay() pushes events with lazy context
3. ProcessEventQueue hits COLLECT_CONTEXT
4. Returns {needsContext = true} to autoExecute()
5. autoExecute() automatically provides context
6. autoExecute() resumes execution
```

**Decision:** ✅ **Extend PlayCard** - Add autoExecute() with built-in context handling

### Step 5: Implementation Plan

```
# Implementation Plan: Havoc Card (Auto-Play)

## Overview
Havoc plays the top card of your draw pile for free. This requires automated card play with context collection.

## Analysis
- **Complexity:** High (new pattern: automated play with context)
- **Scope:** Card + PlayCard extension
- **Reuse:** Foundational (Omniscience, Gambit, future cards use same pattern)

## Decisions
1. **Pipelines:** Extend PlayCard with autoExecute() helper
2. **Queues:** Use existing EventQueue and CardQueue
3. **Engine Changes:** None
4. **World Changes:** None

## Implementation Steps

1. **Create PlayCard.autoExecute()** (`Pipelines/PlayCard.lua`)
   ```lua
   function PlayCard.autoExecute(world, player, card, options)
       -- Options:
       --   skipEnergyCost: bool (true for Havoc)
       --   playSource: string (e.g., "Havoc")
       --   energySpentOverride: number (for X-cost cards)

       -- Save card state
       local originalState = card.state
       card.state = "PROCESSING"

       -- Attempt to play via standard pipeline
       local result = PlayCard.execute(world, player, card, options)

       -- Handle context collection loop
       while result and result.needsContext do
           -- Auto-collect context based on request type
           local request = world.combat.contextRequest

           if request.contextProvider.type == "enemy" then
               -- Auto-select random living enemy
               local target = getRandomLivingEnemy(world)
               if request.contextProvider.stability == "stable" then
                   world.combat.stableContext = target
               else
                   world.combat.tempContext = {target}
               end
           elseif request.contextProvider.type == "cards" then
               -- Auto-select first valid card
               local candidates = getValidCards(world, player, request)
               if request.contextProvider.stability == "stable" then
                   world.combat.stableContext = candidates[1]
               else
                   world.combat.tempContext = {candidates[1]}
               end
           end

           -- Clear request and resume
           world.combat.contextRequest = nil
           result = PlayCard.execute(world, player, card, options)
       end

       -- Restore state on failure
       if not result or result.failed then
           card.state = originalState
           return false
       end

       return true
   end
   ```

2. **Create Havoc card** (`Data/Cards/havoc.lua`)
   ```lua
   Havoc = {
       id = "Havoc",
       name = "Havoc",
       cost = 1,
       type = "SKILL",
       exhausts = true,
       description = "Play the top card of your draw pile. Exhaust.",

       onPlay = function(self, world, player)
           local PlayCard = require("Pipelines.PlayCard")

           world.queue:push({
               type = "ON_CUSTOM_EFFECT",
               effect = function()
                   local Utils = require("utils")
                   local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
                   local topCard = deckCards[1]

                   if not topCard then
                       table.insert(world.log, "Havoc found no card to play.")
                       return
                   end

                   -- Save state for restoration on failure
                   topCard._previousState = topCard.state
                   topCard.state = "PROCESSING"

                   -- Auto-play with free cost
                   local success = PlayCard.autoExecute(world, player, topCard, {
                       skipEnergyCost = true,
                       playSource = "Havoc",
                       energySpentOverride = 0  -- X-cost cards treated as X=0
                   })

                   -- Restore on failure
                   if not success then
                       topCard.state = topCard._previousState or "DECK"
                       topCard._previousState = nil
                       table.insert(world.log, "Havoc failed to play " .. topCard.name)
                   end
               end
           })
       end
   }
   ```

3. **Add energySpentOverride handling** (`Pipelines/PlayCard.lua`)
   ```lua
   -- In prepareCardPlay()
   if options.energySpentOverride ~= nil then
       card.energySpent = options.energySpentOverride
   elseif card.cost == "X" then
       card.energySpent = player.energy  -- Normal X-cost
   end
   ```

## Testing Strategy
- Play Havoc with Strike on top → Strike should auto-play, deal damage
- Play Havoc with X-cost on top → X-cost should play with X=0
- Play Havoc with unplayable card → Should fail gracefully
- Play Havoc with context-needing card → Should auto-select target
- Test energy: Havoc costs 1, played card is free
- Test exhaust: Havoc exhausts after play

## Documentation Updates
- [x] Update PROJECT_MAP.md: Document PlayCard.autoExecute()
- [x] Add to GUIDELINE.md as example of creating pipeline helpers
```

### Step 6: Implementation Result
✅ **Implemented** - Created reusable auto-play system

**Files Modified:**
- `Pipelines/PlayCard.lua` - Added autoExecute() and queueForcedReplay() helpers

**Files Created:**
- `Data/Cards/havoc.lua` - Havoc card
- Later used by: Omniscience, Gambit, etc.

**Key Insight:** Complex card mechanics often require pipeline helpers rather than entirely new pipelines. PlayCard.autoExecute() is used by multiple cards (Havoc, Omniscience, Gambit).

---

## Example 5: Map_ReceiveDamage Pipeline (Map Damage Events)

### Step 0: Understand Architecture
- **What:** Players take damage during map events (curses, event choices)
- **Where:** Map only (outside combat)
- **Interactions:** World HP, potential relic hooks

### Step 1: Pipeline Requirements
**Analysis:**
- Needs to modify `world.player.currentHp` (persistent HP)
- Should cap at 0 (can't go negative)
- Should cap at maxHp (no overheal)
- Might need relic hooks later (e.g., damage reduction relics)
- Mirrors combat damage pattern (consistency)

**Naive approach:**
```lua
-- Map event directly modifies HP
world.player.currentHp = world.player.currentHp - 10
if world.player.currentHp < 0 then world.player.currentHp = 0 end
```

**Problems:**
1. No relic hooks (future-proofing)
2. No logging
3. Inconsistent with combat damage (uses pipeline)
4. Repeated cap logic across events

**Decision:** Create Map_ReceiveDamage pipeline

### Step 2: New Pipeline?
**Question:** Should we create Map_ReceiveDamage pipeline?

**Analysis:**
- **Reuse:** High - Multiple map events cause damage
- **Interactions:** Medium - Potential relic hooks, logging
- **Consistency:** High - Mirrors combat pattern (DealDamage / DealNonAttackDamage)
- **Caps:** Critical - HP must be capped consistently

**Decision:** ✅ **CREATE Map_ReceiveDamage pipeline**

### Step 3: New Queue?
**Question:** Does this need a queue?

**Analysis:**
- Map events already use `world.mapQueue`
- This pipeline is called via map queue: `{type = "MAP_RECEIVE_DAMAGE", amount = 10}`

**Decision:** ✅ **Use existing mapQueue** - No new queue needed

### Step 4: Engine/World Changes?
**Question:** Does World need modification?

**Analysis:**
- `world.player.currentHp` already exists (persistent HP)
- No new state needed

**Decision:** ❌ **NO world changes** - Existing HP field sufficient

**Question:** Does MapEngine need modification?

**Analysis:**
- Map_ProcessQueue already routes events to pipelines
- Just need to add MAP_RECEIVE_DAMAGE to routing table

**Decision:** ✅ **Modify Map_ProcessQueue** - Add routing entry

### Step 5: Implementation Plan

```
# Implementation Plan: Map_ReceiveDamage Pipeline

## Overview
Create pipeline for handling damage during map events (out-of-combat HP loss).

## Analysis
- **Complexity:** Low (simple pipeline, no interactions yet)
- **Scope:** Map events + new pipeline
- **Reuse:** High (multiple events use it)

## Decisions
1. **Pipelines:** CREATE Map_ReceiveDamage.lua
2. **Queues:** Use existing mapQueue
3. **Engine Changes:** Modify Map_ProcessQueue routing
4. **World Changes:** None

## Implementation Steps

1. **Create Map_ReceiveDamage pipeline** (`Pipelines/Map_ReceiveDamage.lua`)
   ```lua
   local Map_ReceiveDamage = {}

   function Map_ReceiveDamage.execute(world, event)
       local player = world.player
       local amount = event.amount or 0
       local source = event.source or "unknown"

       -- Apply damage
       player.currentHp = player.currentHp - amount

       -- Cap at 0 (can't go negative)
       if player.currentHp < 0 then
           player.currentHp = 0
       end

       -- Log
       local Utils = require("utils")
       Utils.log(world, player.name .. " takes " .. amount .. " damage from " .. source)

       -- Potential future: Check for damage reduction relics
       -- for _, relic in ipairs(player.relics) do
       --     if relic.onMapDamage then
       --         relic:onMapDamage(world, player, amount, source)
       --     end
       -- end
   end

   return Map_ReceiveDamage
   ```

2. **Add routing to Map_ProcessQueue** (`Pipelines/Map_ProcessQueue.lua`)
   ```lua
   local DefaultRoutes = {
       MAP_CHOOSE_NODE = require("Pipelines.Map_ChooseNextNode"),
       MAP_RECEIVE_DAMAGE = require("Pipelines.Map_ReceiveDamage"),  -- ADD THIS
       -- ... other routes
   }
   ```

3. **Update map events to use pipeline** (e.g., `Data/MapEvents/Merchant.lua`)
   ```lua
   -- OLD: world.player.currentHp = world.player.currentHp - 6

   -- NEW:
   local MapQueue = require("Pipelines.Map_MapQueue")
   MapQueue.push(world, {
       type = "MAP_RECEIVE_DAMAGE",
       amount = 6,
       source = "Cursed Tome"
   })
   ```

## Testing Strategy
- Trigger map event that causes damage
- Verify: currentHp decreases by correct amount
- Verify: HP capped at 0 (can't go negative)
- Verify: Logging works
- Test edge cases: Damage at 1 HP, damage at 0 HP

## Documentation Updates
- [x] Update PROJECT_MAP.md: Document Map_ReceiveDamage
- [x] Add to GUIDELINE.md as example of creating map pipeline
```

### Step 6: Implementation Result
✅ **Implemented** - New pipeline for consistency and future-proofing

**Files Modified:**
- `Pipelines/Map_ProcessQueue.lua` - Added MAP_RECEIVE_DAMAGE routing

**Files Created:**
- `Pipelines/Map_ReceiveDamage.lua` - New pipeline

**Key Insight:** Even simple operations benefit from pipelines when they:
1. Need consistency (caps, logging)
2. Will be reused (multiple events)
3. Might need hooks later (relics, powers)

---

## Quick Reference: Decision Flowcharts

### Flowchart 1: Should I Create a New Pipeline?

```
START: New mechanic to implement
  ↓
[Is it used by 2+ cards/enemies/relics?]
  ├─ YES → CREATE PIPELINE (high reuse)
  └─ NO → ↓

[Does it have complex interactions? (checks 3+ modifiers)]
  ├─ YES → CREATE PIPELINE (maintainability)
  └─ NO → ↓

[Do other systems need to hook into it?]
  ├─ YES → CREATE PIPELINE (extensibility)
  └─ NO → ↓

[Does it maintain critical invariants? (caps, death, consistency)]
  ├─ YES → CREATE PIPELINE (safety)
  └─ NO → ↓

[Can I compose it from existing pipelines?]
  ├─ YES → USE ON_CUSTOM_EFFECT (combine existing)
  └─ NO → ↓

DEFAULT: Use ON_CUSTOM_EFFECT (one-off mechanic)
```

### Flowchart 2: Should I Create a New Queue?

```
START: Execution ordering problem
  ↓
[Can EventQueue "FIRST" strategy solve it?]
  ├─ YES → USE PRIORITY INSERTION (death, context)
  └─ NO → ↓

[Can existing queue semantics handle it?]
  ├─ YES → USE EXISTING QUEUE (most cases)
  └─ NO → ↓

[Does it have separate lifecycle from events?]
  ├─ YES → CONSIDER NEW QUEUE (map vs combat)
  └─ NO → ↓

[Is LIFO vs FIFO critical to correctness?]
  ├─ YES → CONSIDER NEW QUEUE (card duplication)
  └─ NO → ↓

DEFAULT: DO NOT CREATE QUEUE (almost never needed)
```

### Flowchart 3: Should I Modify CombatEngine?

```
START: Mechanic doesn't fit in pipelines
  ↓
[Does it hijack turn flow? (skip turns, extra turns)]
  ├─ YES → MODIFY ENGINE (Vault)
  └─ NO → ↓

[Does it change win/lose conditions?]
  ├─ YES → MODIFY ENGINE (game ending)
  └─ NO → ↓

[Does it require new handler pattern? (new UI interaction)]
  ├─ YES → MODIFY ENGINE (rare)
  └─ NO → ↓

DEFAULT: DO NOT MODIFY ENGINE (use pipelines + flags)
```

---

## Checklist: Before You Implement

**For every new card/enemy/relic/mechanic, ask:**

### Architecture Analysis
- [ ] Read PROJECT_MAP.md (Step 0)
- [ ] Identify which game systems it interacts with
- [ ] Check if similar mechanics exist (grep through Data/)

### Pipeline Decisions
- [ ] List all game effects needed (damage, block, status, etc.)
- [ ] Identify which existing pipelines handle them
- [ ] Determine if new pipeline needed (use flowchart)
- [ ] If new pipeline: Document why (reuse? complexity? hooks?)

### Queue Decisions
- [ ] Determine if events can be expressed via existing queues
- [ ] Check if execution order is critical (LIFO vs FIFO)
- [ ] Consider if priority insertion ("FIRST") solves it
- [ ] If new queue: Document why (separate lifecycle? stack semantics?)

### Engine/World Decisions
- [ ] Identify any persistent state needed (world.*)
- [ ] Identify any transient state needed (world.combat.*)
- [ ] Check if engine modifications needed (turn flow? win/lose?)
- [ ] Document all state additions and why

### Implementation Plan
- [ ] Write implementation plan (Step 5 template)
- [ ] List all files to create/modify
- [ ] Identify testing strategy
- [ ] Get approval if major architecture change

### Post-Implementation
- [ ] Write tests (tests/ directory)
- [ ] Test manually (edge cases!)
- [ ] Update PROJECT_MAP.md (if new system/pipeline)
- [ ] Update GUIDELINE.md (if novel pattern)
- [ ] Update ARCHITECTURE_NOTES.md (if trade-off involved)

---

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: Over-Abstraction
**Problem:** Creating pipelines/queues for one-off mechanics

**Example:**
```lua
-- WRONG: Creating SplitEnemy pipeline for one boss
Pipelines/SplitEnemy.lua  -- Overkill for single use

-- RIGHT: Direct implementation in enemy
enemy.intents.split = function(self, world, player)
    -- Split logic here
end
```

**Rule:** Don't abstract until you have 2-3 use cases.

### ❌ Anti-Pattern 2: Direct State Mutation
**Problem:** Bypassing pipelines for effects that have hooks

**Example:**
```lua
-- WRONG: Direct HP loss bypasses relics/modifiers
world.player.currentHp = world.player.currentHp - 10

-- RIGHT: Use pipeline
world.queue:push({
    type = "ON_NON_ATTACK_DAMAGE",
    source = self,
    target = player,
    amount = 10,
    tags = {"ignoreBlock"}
})
```

**Rule:** If modifiers/hooks exist or might exist, use pipelines.

### ❌ Anti-Pattern 3: Queue Abuse
**Problem:** Using queues for control flow instead of data flow

**Example:**
```lua
-- WRONG: Trying to queue "skip enemy turns"
world.queue:push({type = "SKIP_ENEMY_TURNS"})  -- Doesn't make sense

-- RIGHT: Use flag + engine cooperation
world.combat.vaultPlayed = true  -- CombatEngine checks this
```

**Rule:** Queues are for events (data), not control flow.

### ❌ Anti-Pattern 4: Context Misuse
**Problem:** Not using lazy evaluation for context-dependent values

**Example:**
```lua
-- WRONG: Context doesn't exist yet
world.queue:push({
    type = "ON_DAMAGE",
    defender = world.combat.stableContext  -- nil!
})

-- RIGHT: Lazy evaluation
world.queue:push({
    type = "ON_DAMAGE",
    defender = function() return world.combat.stableContext end  -- Evaluated later
})
```

**Rule:** Wrap context references in functions.

### ❌ Anti-Pattern 5: State Pollution
**Problem:** Adding persistent state for transient effects

**Example:**
```lua
-- WRONG: Adding world field for one-time card effect
world.catalystUsedThisCombat = true  -- Pollutes world

-- RIGHT: Track in combat context if needed
world.combat.catalystUsedThisCombat = true  -- Cleared at EndCombat
```

**Rule:** Persistent state (world.*) only for cross-combat/cross-map data.

---

## Example 6: Nightmare Card (Delayed Card Addition)

### Step 0: Understand Architecture
- **What:** Card that adds 3 copies of chosen card to hand **next turn**
- **Where:** Combat only, delayed effect
- **Interactions:** Card selection, turn cycle, hand size limits

### Step 1: Pipeline Requirements
**Analysis:**
- Needs card selection → Context system
- Needs delayed delivery → Cross-turn state tracking
- Needs hand size enforcement → StartTurn integration

**Initial Wrong Ideas (Cautionary Tale):**

**❌ Wrong Idea 1:** "Use temp context for card selection"
- **Reasoning (WRONG):** "Temp context is cleared after queue drain, won't persist"
- **Problem:** Misunderstood the question! The issue isn't persistence to next turn
- **Real reason for stable:** Duplications (Double Tap, Echo Form) must select SAME card
- **Lesson:** Stable vs temp is about duplication behavior, not turn persistence

**❌ Wrong Idea 2:** "Store selected card in world.combat.nightmareQueue"
- **Reasoning:** "Need to persist across turns, context won't work"
- **Problem:** Adds tracking structure when card state would work
- **Better:** Cards live in combatDeck with special state

**❌ Wrong Idea 3:** "Store card reference in world.combat for persistence"
- **Reasoning:** "Stable context is for 'current card execution', not cross-turn"
- **Problem:** True, but misses the simpler solution
- **Reality:** Don't use context system for storage at all - just create cards immediately

**✅ Correct Solution:**
1. Use **stable context** for selection (because duplications must use same card)
2. Create copies immediately with `state = "NIGHTMARE"` (no separate tracking)
3. StartTurn moves NIGHTMARE → HAND (simple state transition)

**Decision:** Create copies with special state, no tracking structure needed

### Step 2: New Pipeline?
**Question:** Need NightmareDelivery pipeline?

**Analysis:**
- Just state transition logic (NIGHTMARE → HAND)
- Single responsibility, fits in StartTurn
- No complex interactions

**Decision:** ❌ **NO new pipeline** - Extend StartTurn with state check

### Step 3: New Queue?
**Decision:** ❌ **NO** - Card state approach eliminates need

### Step 4: Engine/World Changes?
**Question:** Where do NIGHTMARE cards live?

**Analysis:**
- They're cards → live in `player.combatDeck`
- Just need state: `card.state = "NIGHTMARE"`
- StartTurn checks this state

**Decision:**
- ❌ NO world changes
- ✅ Modify StartTurn to handle NIGHTMARE state

### Step 5: Implementation Plan

```
# Implementation Plan: Nightmare Card

## Overview
Nightmare creates 3 copies of a chosen card that arrive next turn.

## Analysis
- **Complexity:** Low-Medium (new card state, but simple logic)
- **Scope:** Card + StartTurn modification
- **Reuse:** Card state pattern reusable for other delayed effects

## Decisions
1. **Pipelines:** Use existing (COLLECT_CONTEXT), modify StartTurn
2. **Queues:** None - card state approach
3. **Engine Changes:** None
4. **World Changes:** None - cards live in combatDeck with special state

## Implementation Steps

1. **Create Nightmare card** (`Data/Cards/nightmare.lua`)
   - Use **stable context** (same card for duplications)
   - Create 3 copies with `state = "NIGHTMARE"`
   - Bypass AcquireCard (direct creation)

2. **Modify StartTurn** (`Pipelines/StartTurn.lua`)
   - After drawing cards, process NIGHTMARE state
   - Respect max hand size (default 10)
   - Remove cards entirely if hand full (not discard)

## Testing Strategy
- Basic: 3 copies added next turn
- Full hand: Cards lost when hand full
- Duplication: Stable context persists (6 copies with Echo Form)
```

### Step 6: Implementation Result
✅ **Implemented** - New card state pattern established

**Files Created:**
- `Data/Cards/nightmare.lua`
- `tests/test_nightmare.lua`

**Files Modified:**
- `Pipelines/StartTurn.lua` - Added NIGHTMARE state handling (lines 131-151)

**Key Code:**
```lua
-- In Nightmare.onPlay
for i = 1, 3 do
    local copy = Utils.deepCopyCard(selectedCard)
    copy.state = "NIGHTMARE"
    table.insert(player.combatDeck, copy)
end

-- In StartTurn.execute
for i = #player.combatDeck, 1, -1 do
    local card = player.combatDeck[i]
    if card.state == "NIGHTMARE" then
        local handSize = Utils.getCardCountByState(player.combatDeck, "HAND")
        if handSize < maxHandSize then
            card.state = "HAND"
        else
            table.remove(player.combatDeck, i)  -- Lost if hand full
        end
    end
end
```

**Key Insights:**
- **Card state pattern** > tracking structures for single mechanic
- **Stable context critical** - duplication must use same card
- **Simplest solution:** No new queues, no world state, just state transition

---

## Example 7: Master Reality (Shared Logic Across Pipelines)

### Step 0: Understand Architecture
- **What:** Power that auto-upgrades any card created during combat
- **Where:** Combat only, affects card creation
- **Interactions:** AcquireCard pipeline, Nightmare card (and any future card creators)

### Step 1: Pipeline Requirements
**Analysis:**
- Needs to trigger on **any** card creation
- AcquireCard handles most card creation
- But Nightmare **bypasses** AcquireCard (creates directly)

**Initial Wrong Ideas (Cautionary Tale):**

**❌ Wrong Idea 1:** "Put upgrade logic only in AcquireCard"
- **Problem:** Nightmare bypasses AcquireCard, won't get upgraded
- **Miss:** Cards created outside pipeline

**❌ Wrong Idea 2:** "Create MasterRealityUpgrade pipeline, call everywhere"
- **Problem:** Overkill - it's just `if power then card.onUpgrade() end`
- **Overengineering:** 3-line check doesn't need abstraction

**❌ Wrong Idea 3:** "Force Nightmare to use AcquireCard"
- **Problem:** Nightmare needs NIGHTMARE state, AcquireCard sets state to HAND
- **Architectural mismatch:** Different responsibilities

**✅ Correct Solution:** Duplicate the check in both places
- AcquireCard gets upgrade check
- Nightmare gets upgrade check
- Simple, explicit, maintainable

**Decision:** Add auto-upgrade logic to both locations

### Step 2: New Pipeline?
**Question:** Create MasterRealityUpgrade helper pipeline?

**Analysis:**
```lua
-- The "pipeline" would be:
if Utils.hasPower(player, "MasterReality") then
    if not card.upgraded and type(card.onUpgrade) == "function" then
        card:onUpgrade()
        card.upgraded = true
    end
end
```

- **3 lines of code**
- **2 use cases** (AcquireCard, Nightmare)
- **No complex interactions**
- **Abstracting would add more code than it saves**

**Decision:** ❌ **NO new pipeline** - Duplicate check in both places

### Step 3: New Queue?
**Decision:** ❌ **NO** - Not an async operation

### Step 4: Engine/World Changes?
**Question:** Does Master Reality need world state?

**Analysis:**
- It's a power → lives in `player.powers`
- No cross-turn tracking needed
- No persistent state beyond power existence

**Decision:** ❌ **NO world/engine changes** - Just power check

### Step 5: Implementation Plan

```
# Implementation Plan: Master Reality Power

## Overview
Power that auto-upgrades cards created during combat.

## Analysis
- **Complexity:** Low (simple power check)
- **Scope:** Power + Card + 2 pipeline modifications
- **Reuse:** Pattern for "hooks without abstraction"

## Decisions
1. **Pipelines:** Modify AcquireCard + Nightmare (duplicate logic)
2. **Queues:** None
3. **Engine Changes:** None
4. **World Changes:** None (power is sufficient)

## Implementation Steps

1. **Create Master Reality power** (`Data/Powers/masterreality.lua`)
2. **Create Master Reality card** (`Data/Cards/masterreality.lua`)
3. **Add logic to AcquireCard** (`Pipelines/AcquireCard.lua`)
4. **Add logic to Nightmare** (`Data/Cards/nightmare.lua`)

## Key Pattern: Shared Logic Without Abstraction

When logic appears in 2 places:
- **< 5 lines:** Duplicate it (simple, explicit)
- **2-3 use cases:** Duplicate it (abstraction cost > duplication cost)
- **> 3 use cases OR complex:** Extract to helper

Master Reality is 3 lines, 2 places → Duplicate
```

### Step 6: Implementation Result
✅ **Implemented** - Shared logic pattern established

**Files Created:**
- `Data/Powers/masterreality.lua`
- `Data/Cards/masterreality.lua`
- `tests/test_masterreality.lua`

**Files Modified:**
- `Pipelines/AcquireCard.lua` - Added upgrade check (lines 32-38)
- `Data/Cards/nightmare.lua` - Added upgrade check (lines 50-56)

**Key Code (duplicated in both places):**
```lua
-- Check for Master Reality power: auto-upgrade created cards
if Utils.hasPower(player, "MasterReality") then
    if not newCard.upgraded and type(newCard.onUpgrade) == "function" then
        newCard:onUpgrade()
        newCard.upgraded = true
    end
end
```

**Why Duplication is Correct Here:**

| Factor | Analysis |
|--------|----------|
| **Lines of code** | 3 lines (trivial to duplicate) |
| **Use cases** | 2 places (AcquireCard, Nightmare) |
| **Complexity** | Zero - just a check and call |
| **Abstraction cost** | Would need: helper function, 2 imports, 2 calls = more code |
| **Maintenance risk** | Low - if logic changes, easy to find both (grep "MasterReality") |
| **Clarity** | High - explicit is better than hidden |

**Cautionary Tale Lessons:**

1. **Not everything needs a pipeline** - 3 lines don't
2. **Duplication < abstraction** when abstraction costs more
3. **Grep-ability matters** - "MasterReality" finds both places instantly
4. **Bypassing pipelines happens** - cards can create cards directly
5. **Shared logic ≠ shared code** - sometimes duplicate is cleaner

**When to Abstract:**
- **> 5 lines** of logic
- **> 3 use cases**
- **Complex interactions** (multiple modifiers, state management)
- **Frequently changing** (centralize to reduce update burden)

**When to Duplicate:**
- **< 5 lines** of logic
- **2-3 use cases**
- **Simple checks** (no complex state)
- **Stable** (rarely changes)

**Rule of Thumb:** Duplicate twice, abstract thrice. Master Reality has 2 uses → duplicate is correct.

---

## Summary: The Decision-Making Framework

**The 6-Step Process:**

1. **Step 0:** Read PROJECT_MAP.md, understand architecture
2. **Step 1:** Identify pipeline requirements (existing vs new)
3. **Step 2:** Decide if new pipeline needed (use flowchart)
4. **Step 3:** Decide if new queue needed (almost always no)
5. **Step 4:** Identify engine/world modifications (minimal when possible)
6. **Step 5:** Write implementation plan (Step 5 template)
7. **Step 6:** Implement, test, document

**Key Principles:**

- **Simplicity First:** Use existing systems before creating new ones
- **Reuse Threshold:** Create abstractions at 2-3 use cases, not before
- **Consistency:** Mirror existing patterns (combat ↔ map)
- **Debuggability:** Prefer explicit over clever (no magic)
- **Documentation:** Every new system needs PROJECT_MAP update

**When in Doubt:**

1. Look for similar existing mechanics (grep through Data/)
2. Use ON_CUSTOM_EFFECT as fallback (always works)
3. Ask: "Would this confuse someone reading the code in 6 months?"
4. Default to simpler solution (direct > helper > pipeline > engine modification)

---

## Step 7: Writing Effective Tests

### The Golden Rules of Testing

**Based on fixing 17 failing tests, here are the hard-learned lessons:**

#### Rule 1: Enemies Must Survive Expected Damage

**Problem:** HP is capped to [0, maxHp] AFTER damage calculation by `ApplyCaps.lua`.

```lua
-- ❌ BAD TEST: Enemy dies, can't verify full damage
enemy.hp = 12
FirePotion deals 15 damage
assert(enemy.hp == -3)  -- WRONG! HP capped to 0

-- ✅ GOOD TEST: Enemy survives, damage fully measurable
enemy.hp = 20
FirePotion deals 15 damage
assert(enemy.hp == 5)  -- 20 - 15 = 5 ✅
```

**Rule of Thumb:** Enemy HP ≥ (expected_damage + 5) for safety margin.

#### Rule 2: Player Needs Sufficient Energy

**Problem:** Tests were hanging in infinite loops when `PlayCard.execute()` returned `false` (insufficient energy).

```lua
-- ❌ BAD: Default maxEnergy = 3, need 5 Strikes
maxEnergy = 3
for i = 1, 5 do playCard(Strike) end  -- Runs out at card 4!

-- ✅ GOOD: Provide enough energy
maxEnergy = 6  -- Can play 6 cards at cost 1
for i = 1, 5 do playCard(Strike) end
```

**Context Loop Safety:**
```lua
while true do
    local result = PlayCard.execute(world, player, card)
    if result == true then
        break
    elseif result == false then  -- ← CRITICAL: Prevents infinite loop
        break
    end
    -- Handle context...
end
```

#### Rule 3: Use NoShuffle for Deterministic Tests

**Problem:** Deck shuffling breaks tests that depend on card order.

```lua
-- ❌ BAD: Random card order
StartCombat.execute(world)  -- Shuffles deck!

-- ✅ GOOD: Deterministic order
world.NoShuffle = true
StartCombat.execute(world)
-- Cards drawn in exact order they were added
```

**When to Use:**
- Testing Havoc (plays top card of deck)
- Testing card selection with labeled cards
- Multi-duplication tests where order matters

#### Rule 4: Account for Card States After Cancellation

**Problem:** Cancelled cards stay in `PROCESSING` state, not `DISCARD_PILE`.

```lua
-- ❌ BAD: Only counts DISCARD_PILE
local played = countCardsInState(deck, "DISCARD_PILE")
assert(played == 4)  -- FAILS if duplication was cancelled

-- ✅ GOOD: Count both states
local played = countCardsInState(deck, "DISCARD_PILE") +
               countCardsInState(deck, "PROCESSING")
assert(played == 4)  -- Handles cancellations
```

**Why This Happens:** When enemy dies mid-duplication, remaining plays are cancelled. The card remains in `PROCESSING` instead of moving to `DISCARD_PILE`.

#### Rule 5: Test Duplication Stacking Systematically

**When testing Double Tap, Echo Form, Burst, Necronomicon:**

1. Calculate total hits: initial + duplications
2. Calculate total damage: hits × damage_per_hit
3. Set enemy HP ≥ total_damage
4. Set player energy ≥ card_cost
5. Enable NoShuffle if order matters
6. Verify trigger messages in log

```lua
-- TEST: Double Tap + Echo Form
-- Expected: 1 initial + 1 Double Tap + 1 Echo Form = 3 hits
local totalHits = 3
local damagePerHit = 6  -- Strike
local totalDamage = totalHits * damagePerHit  -- 18

enemy.hp = 20  -- ≥ 18
enemy.maxHp = 20
player.energy = 3  -- ≥ 1 (Strike cost)
player.status.doubleTap = 1
player.status.echoFormThisTurn = 1

playCard(Strike)

assert(countLogEntries(log, "Double Tap triggers!") == 1)
assert(countLogEntries(log, "Echo Form triggers!") == 1)
assert(countLogEntries(log, "dealt 6 damage") == 3)
assert(enemy.hp == 2)  -- 20 - 18 = 2
```

#### Rule 6: World.createWorld Accepts Testing Parameters

**Critical Parameters:**

```lua
World.createWorld({
    id = "IronClad",
    maxHp = 80,
    maxEnergy = 6,              -- Override default 3
    energy = 5,                 -- Start with specific energy
    cards = {card1, card2},     -- Starting deck
    relics = {relic1},          -- Starting relics
    masterPotions = {potion1}   -- Starting potions
})
```

**Fixed Bug (2025-11-13):** World.lua now respects `maxEnergy` parameter (was hardcoded to 3).

### Test Template Library

#### Template 1: Simple Combat Test

```lua
local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")

math.randomseed(1337)

local function playCardWithAutoContext(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then return true end
        if result == false then break end  -- Prevent infinite loop

        if type(result) == "table" and result.needsContext then
            local request = world.combat.contextRequest
            local context = ContextProvider.execute(world, player,
                                                    request.contextProvider,
                                                    request.card)
            if request.stability == "stable" then
                world.combat.stableContext = context
            else
                world.combat.tempContext = context
            end
            world.combat.contextRequest = nil
        end
    end
end

-- Setup
local world = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    maxEnergy = 6,
    cards = {Utils.copyCardTemplate(Cards.Strike)},
    relics = {}
})

world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
world.NoShuffle = true
StartCombat.execute(world)

-- Modify as needed
world.enemies[1].hp = 20
world.enemies[1].maxHp = 20

-- Test
local card = world.player.combatDeck[1]  -- First card in hand
playCardWithAutoContext(world, world.player, card)

-- Assert
assert(world.enemies[1].hp < 20, "Enemy should take damage")
print("✓ Test passed")
```

#### Template 2: Duplication Test

```lua
-- Calculate requirements
local hits = 3  -- initial + Double Tap + Echo Form
local damagePerHit = 6
local totalDamage = hits * damagePerHit

-- Setup with sufficient resources
local world = World.createWorld({
    id = "IronClad",
    maxEnergy = 6,  -- Enough for multiple cards
    cards = {Utils.copyCardTemplate(Cards.Strike)},
    relics = {}
})

world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
world.NoShuffle = true
StartCombat.execute(world)

-- Ensure survival
world.enemies[1].hp = totalDamage + 5
world.enemies[1].maxHp = totalDamage + 5

-- Enable duplications
world.player.status.doubleTap = 1
world.player.status.echoFormThisTurn = 1

-- Test
playCardWithAutoContext(world, world.player, strikeCard)

-- Verify logs (triggers BEFORE execution)
assert(countLogEntries(world.log, "Double Tap triggers!") == 1)
assert(countLogEntries(world.log, "Echo Form triggers!") == 1)

-- Verify damage
local expectedHp = (totalDamage + 5) - totalDamage
assert(world.enemies[1].hp == expectedHp)
```

#### Template 3: Enemy AI Test

```lua
local world = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    cards = {Utils.copyCardTemplate(Cards.Strike)},
    relics = {}
})

local boss = Utils.copyEnemyTemplate(Enemies.SlimeBoss)
world.enemies = {boss}
StartCombat.execute(world)

-- Damage boss below threshold
-- NOTE: Give enough energy to reach threshold!
world.player.energy = 6
for i = 1, 5 do
    local strike = findCardByType(world.player.combatDeck, "Strike")
    playCardWithAutoContext(world, world.player, strike)
end

-- Verify intent changed
assert(boss.hasSplit == true, "Boss should set split flag")
assert(boss.currentIntent.name == "Split", "Boss should have Split intent")
```

### Common Test Failures & Fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| "Expected 4 cards, got 3" | Cancelled card in PROCESSING | Count DISCARD_PILE + PROCESSING |
| "Expected 15 damage, got 12" | Enemy died, HP capped | Increase enemy.hp ≥ expected_damage |
| Test hangs indefinitely | Infinite loop on `result == false` | Add `elseif result == false then break` |
| "Not enough energy" | Default maxEnergy = 3 too low | Set maxEnergy = 6+ in createWorld |
| Cards in wrong order | Deck shuffled | Set world.NoShuffle = true |
| "Echo Form should trigger" | Power not set up | Add power to player.powers + set status counter |

### Testing Checklist

Before submitting a test:

- [ ] Enemy HP ≥ expected total damage + 5
- [ ] Player maxEnergy ≥ total card costs
- [ ] world.NoShuffle = true if order matters
- [ ] Context loop handles `result == false`
- [ ] Count PROCESSING + DISCARD_PILE for played cards
- [ ] Verify log entries for trigger messages
- [ ] Test passes with `math.randomseed(1337)` for deterministic randomness

---

**Happy implementing!**
