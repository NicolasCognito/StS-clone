# Project Map - Slay the Spire Clone

**Last Updated:** 2025-11-13

This document explains the architecture, relationships between components, and how to navigate/modify the codebase.

---

## Architecture Philosophy

This codebase follows a **Centralized Pipeline Architecture**:

- **Content is data**, not OOP classes - Cards, enemies, relics generate events, don't execute logic
- **All game logic lives in pipelines** - ONE place per mechanic (damage, block, status effects, etc.)
- **Dual queue-based event system** - EventQueue (FIFO) for events, CardQueue (LIFO) for card execution
- **No inheritance/polymorphism** - Extensible through visibility (Ctrl+F), not modularity
- **Auto-loading** - Drop new files in `Data/Cards/`, `Data/Powers/`, `Data/Enemies/`, etc. and they load automatically
- **Data-driven design** - Status effects, encounters, and map events are declarative configurations

**Key Insight:** The architecture prioritizes **debuggability** and **visibility** over **modularity**. When something breaks, Ctrl+F will find THE place where it happens.

---

## Directory Structure

```
StS-clone/
├── main.lua                    # Entry point for the game
├── World.lua                   # World state structure (player, deck, map)
├── CombatEngine.lua            # Combat loop, handles player input and turn flow
├── MapEngine.lua               # Map event orchestration and progression
├── MapCLI.lua                  # CLI for map/progression interface
│
├── Pipelines/                  # ALL game logic lives here
│   ├── Combat Pipelines:
│   │   ├── PlayCard.lua        # Card playing orchestration
│   │   ├── ResolveCard.lua     # CardQueue processor
│   │   ├── ProcessEventQueue.lua # Routes combat events to handlers
│   │   ├── EventQueue.lua      # FIFO queue for game events
│   │   ├── CardQueue.lua       # LIFO stack for card execution
│   │   ├── EventQueueOver.lua  # Cleanup when queue empties
│   │   ├── StartTurn.lua       # Player turn initialization
│   │   ├── EndTurn.lua         # Player turn cleanup
│   │   ├── EndRound.lua        # Round-end status tick down
│   │   ├── EnemyTakeTurn.lua   # Enemy turn execution
│   │   ├── StartCombat.lua     # Combat initialization
│   │   ├── EndCombat.lua       # Combat cleanup
│   │   ├── DealDamage.lua      # Damage calculation (strength, vulnerable, weak)
│   │   ├── DealNonAttackDamage.lua # Non-attack damage (HP loss effects)
│   │   ├── ApplyBlock.lua      # Block calculation (dexterity, frail)
│   │   ├── ApplyStatusEffect.lua # Status effect application
│   │   ├── ApplyCaps.lua       # Enforce HP/block caps and death checks
│   │   ├── Death.lua           # Entity death handling
│   │   ├── DrawCard.lua        # Card drawing logic
│   │   ├── Discard.lua         # Card discard logic
│   │   ├── Exhaust.lua         # Card exhaust logic
│   │   ├── GetCost.lua         # Dynamic cost calculation
│   │   ├── AcquireCard.lua     # Add card to deck/hand
│   │   ├── ContextProvider.lua # Context collection (target selection)
│   │   ├── ClearContext.lua    # Context cleanup
│   │   ├── AfterCardPlayed.lua # Post-card-play triggers
│   │   ├── UsePotion.lua       # Potion usage
│   │   ├── Heal.lua            # Healing
│   │   ├── Scry.lua            # Scry mechanic
│   │   ├── ChangeStance.lua    # Stance system (Watcher)
│   │   ├── ChannelOrb.lua      # Orb channeling (Defect)
│   │   ├── EvokeOrb.lua        # Orb evocation
│   │   └── OrbPassive.lua      # Orb passive effects
│   │
│   └── Map Pipelines:
│       ├── Map_ProcessQueue.lua     # Routes map events to handlers
│       ├── Map_ChooseNextNode.lua   # Node navigation
│       ├── Map_StartCombat.lua      # Initiate combat from map
│       ├── Map_AcquireRelic.lua     # Relic acquisition
│       ├── Map_Heal.lua             # Out-of-combat healing
│       ├── Map_ReceiveDamage.lua    # Out-of-combat damage
│       ├── Map_RemoveCard.lua       # Remove card from deck
│       ├── Map_UpgradeCard.lua      # Upgrade card
│       └── Map_BuildCardPool.lua    # Generate card selection pools
│
├── Data/                       # Game content definitions
│   ├── Auto-loaded modules:
│   │   ├── cards.lua           # Auto-loader for cards
│   │   ├── Cards/              # Individual card definitions
│   │   │   ├── strike.lua
│   │   │   ├── defend.lua
│   │   │   ├── omniscience.lua
│   │   │   └── ... (120+ cards)
│   │   ├── powers.lua          # Auto-loader for powers
│   │   ├── Powers/             # Individual power definitions
│   │   ├── relics.lua          # Auto-loader for relics
│   │   ├── Relics/             # Individual relic definitions
│   │   ├── enemies.lua         # Auto-loader for enemies
│   │   ├── Enemies/            # Individual enemy definitions
│   │   │   ├── slime.lua       # Acid Slime, Spike Slime, Slime Boss
│   │   │   ├── goblin.lua
│   │   │   └── cultist.lua
│   │   ├── potions.lua         # Auto-loader for potions
│   │   └── Potions/            # Individual potion definitions
│   │
│   ├── Data structures:
│   │   ├── statuseffects.lua   # Status effect metadata
│   │   ├── orbs.lua            # Orb definitions (Defect)
│   │   ├── encounters.lua      # Enemy encounter definitions
│   │   └── loader_utils.lua    # Shared auto-loading utilities
│   │
│   ├── Map content:
│   │   ├── Maps/               # Map structure definitions
│   │   │   └── testmap.lua     # Node graph with connections
│   │   └── MapEvents/          # Map event state machines
│   │       ├── SimpleCombat.lua
│   │       ├── Campfire.lua    # Rest/Smith/Lift/Toke/Dig/Recall
│   │       ├── Merchant.lua    # Shop with cards/relics/removal
│   │       └── _ReusableNodes.lua # Common event patterns
│   │
│   └── Library modules:
│       └── EventLibrary.lua    # Map event registry and helpers
│
├── Utils/                      # Validation and helpers
│   └── ContextValidators.lua   # Context validation functions
│
├── tests/                      # Test files
│   ├── test_doubletap.lua
│   ├── test_orbs.lua
│   ├── test_potions.lua
│   └── ... (comprehensive test suite)
│
├── Docs/                       # Documentation
│   ├── PROJECT_MAP.md          # This file
│   ├── GUIDELINE.md            # Developer guide for adding content
│   ├── TODOs.md                # Known issues and future work
│   ├── ADDING_CARDS_AND_RELICS.md  # Implementation examples
│   ├── ARCHITECTURE_NOTES.md   # Design decisions
│   └── centralized-pipeline-architecture.md # Architecture deep dive
│
└── utils.lua                   # Shared utility functions
```

---

## Core Systems Overview

### 1. WORLD STATE (World.lua)

The **World** is the persistent game state container that lives across all combats and map traversal.

**Key Structures:**

```lua
world = {
    player = {
        -- Identity & Stats
        id, name, maxHp, currentHp, hp, block, energy, maxEnergy,

        -- Deck System (CRITICAL DUAL ARCHITECTURE)
        masterDeck,    -- PERSISTENT: Permanent card collection
        combatDeck,    -- TEMPORARY: Deep copy during combat only

        -- Consumables & Relics
        masterPotions, relics, gold,

        -- Combat-only (nil outside combat)
        status, powers,

        -- Character-specific
        currentStance,        -- Watcher (Calm, Wrath, Divinity)
        orbs, maxOrbs,        -- Defect (orb slots)
        permanentStrength     -- Applied at combat start
    },

    -- Combat state (nil outside combat)
    enemies, combat, queue, cardQueue, log,

    -- Map/Progression
    map, currentNode, floor, mapQueue, mapEvent,

    -- Persistent relic state
    wingedBootsCharges, penNibCounter, giryaLiftsUsed, ...
}
```

**Key Concepts:**
- **Dual Deck System**: `masterDeck` is permanent, `combatDeck` is a combat-only deep copy
- **HP Sync**: `currentHp` persists, `hp` is synced at combat boundaries
- **Combat Context**: `status`, `powers`, `combatDeck` only exist during combat
- **Logic-Free**: World.lua shapes state, contains zero game logic

---

### 2. COMBAT FLOW (CombatEngine.lua)

**Main Game Loop:**

```
while not gameOver:
    1. Render game state (via handlers.onRenderState)
    2. Check for context request OR get player action
    3. Execute action (play card, use potion, or end turn)
    4. Process queues (event queue → card queue → repeat)
    5. Check win/lose conditions
```

**Turn Cycle:**

```
PLAYER TURN:
  StartTurn.execute()
    → Exit Divinity stance (if active)
    → Clear turn flags (cannotDraw, necronomiconThisTurn)
    → Process start-of-turn status (Shackled, Bias, Wraith Form)
    → Set Echo Form counter from power stacks
    → Reset player block to 0
    → Draw 5 cards (+ Snecko Eye bonus - penalties)
    → Enemies select intents (AI chooses next action)

  Player Actions Loop:
    → Play card (PlayCard.execute)
    → Use potion (UsePotion.execute)
    → End turn

  EndTurn.execute()
    → Trigger relic onEndCombat effects
    → Process event queue
    → Trigger orb passive effects (Lightning damage, Frost block, Dark accumulate)
    → Handle Retain mechanics (Runic Pyramid, retain cards)
    → Discard non-retained cards
    → Clear turn flags (costsZeroThisTurn, enlightenedThisTurn)
    → Reset combat trackers (cardsDiscardedThisTurn)
    → Reset energy to maxEnergy

ENEMY TURNS (for each living enemy):
  EnemyTakeTurn.execute(enemy)
    → Process enemy start-of-turn status (Bias, Wraith Form)
    → Reset enemy block to 0
    → Log enemy intent
    → Execute enemy.executeIntent() (pushes events to queue)
    → Process event queue

END OF ROUND:
  EndRound.execute()
    → Remove block (unless Barricade power active)
    → Tick down status effects (vulnerable--, weak--, etc.)
    → Applies to player AND all enemies

  → Back to StartTurn (new player turn begins)
```

**Special Mechanics:**
- **Vault Card**: Sets `world.combat.vaultPlayed` flag → skips enemy turns AND EndRound entirely
- **Context System**: Pauses execution when cards need targets, resumes after selection
- **Win/Lose**: Checked after every action (card play, potion use, end turn)

---

### 3. DUAL QUEUE SYSTEM

The game uses **two queues** working in tandem:

#### EventQueue (FIFO - First In, First Out)

**Location:** `Pipelines/EventQueue.lua`

**Purpose:** Sequential processing of game events (damage, block, status, etc.)

**Operations:**
```lua
world.queue:push(event, strategy)  -- strategy: "LAST" (default) or "FIRST"
world.queue:next()                 -- Pop and return first event
world.queue:isEmpty()
world.queue:clear()
```

**Key Patterns:**
- Normal events: Push with `"LAST"` (FIFO order)
- Context requests: Push with `"FIRST"` (priority - must run before dependent events)
- Lazy evaluation: Event fields can be functions evaluated during processing

**Event Types:**
- `ON_DAMAGE`, `ON_NON_ATTACK_DAMAGE`, `ON_BLOCK`, `ON_HEAL`
- `ON_STATUS_GAIN`, `ON_APPLY_POWER`
- `ON_DRAW`, `ON_DISCARD`, `ON_EXHAUST`, `ON_ACQUIRE_CARD`
- `COLLECT_CONTEXT`, `CLEAR_CONTEXT`, `AFTER_CARD_PLAYED`
- `ON_CHANNEL_ORB`, `ON_EVOKE_ORB`, `ON_SCRY`
- `ON_CUSTOM_EFFECT`, `ON_DEATH`

#### CardQueue (LIFO - Last In, First Out)

**Location:** `Pipelines/CardQueue.lua`

**Purpose:** Schedule card executions (initial play + duplications)

**Operations:**
```lua
world.cardQueue:push(entry)      -- Push execution entry to stack
world.cardQueue:pop()            -- Pop and return top entry
world.cardQueue:pushSeparator()  -- Visual marker between cards
```

**Entry Structure:**
```lua
{
    card = card,                  -- The card instance
    player = player,              -- The player
    options = options,            -- Play options (skipEnergyCost, etc.)
    replaySource = "Double Tap",  -- nil for initial, source for replays
    isInitial = true,             -- true for first play, false for duplications
    isLast = false,               -- true for final duplication (discard/exhaust)
    phase = "main",               -- "main" or "duplication"
    skipDiscard = false,          -- don't discard yet (non-final duplication)
    resuming = false              -- resuming after context collection
}
```

**Why LIFO?**

Ensures correct execution order for duplication chains:

```
PUSH ORDER (bottom → top):     POP ORDER (top → bottom):
1. Initial play                1. Duplication 2 (Echo Form)
2. Duplication 1 (Double Tap)  2. Duplication 1 (Double Tap)
3. Duplication 2 (Echo Form)   3. Initial play
```

This creates the expected visual: initial → duplicate 1 → duplicate 2

#### Queue Interaction Flow

```
1. Player plays card
   ↓
2. PlayCard.execute()
   → Build duplication plan (Double Tap, Burst, Echo Form, Necronomicon)
   → Push entries to CardQueue in reverse order (LIFO)
   ↓
3. First entry pops from CardQueue
   → PlayCard.executeCardEffect()
   → card.onPlay() pushes events to EventQueue
   ↓
4. ProcessEventQueue.execute()
   → Drain EventQueue (FIFO) until empty
   → Routes events to pipelines (DealDamage, ApplyBlock, etc.)
   → If needs context: pause, collect, resume
   ↓
5. EventQueueOver.execute()
   → Clear temp context
   → Clear stable context (unless deferred)
   → Trigger ResolveCard.execute()
   ↓
6. ResolveCard.execute()
   → Pop next entry from CardQueue (next duplication)
   → Repeat from step 3 until CardQueue empty
```

**Key Insight:** CardQueue handles WHEN cards execute (scheduling), EventQueue handles WHAT effects happen (game events). This separation enables complex duplication stacking and event-driven architecture.

---

### 4. CONTEXT SYSTEM (Target Selection)

Cards often need user input (enemy target, card selection). The **context system** handles this:

**Two Context Types:**

```lua
world.combat = {
    stableContext = entity,     -- Persists across duplications (enemy target)
    tempContext = {cards...},   -- Re-collected per duplication (card selections)
    contextRequest = request,   -- Pending context request
    deferStableContextClear = flag  -- Prevent premature clearing
}
```

**Context Collection Pattern:**

```lua
-- STEP 1: Request context (FIRST priority)
world.queue:push({
    type = "COLLECT_CONTEXT",
    card = self,
    contextProvider = {
        type = "enemy",           -- or "cards"
        stability = "stable",     -- or "temp"

        -- For card context:
        source = "combat",        -- or "master" for permanent deck
        count = {min = 1, max = 1},  -- selection bounds
        filter = function(world, player, card, candidate)
            return candidate.state == "DISCARD_PILE"
        end
    }
}, "FIRST")  -- Must be FIRST to run before dependent events

-- STEP 2: Use context (lazy evaluation)
world.queue:push({
    type = "ON_DAMAGE",
    attacker = player,
    defender = function() return world.combat.stableContext end,  -- Deferred!
    card = self
})
```

**Stability:**
- **Stable**: Persists across duplications
  - Example: Strike with Double Tap hits same enemy twice
  - Validated before each duplication via `card.stableContextValidator`
- **Temp**: Re-collected for each duplication
  - Example: Headbutt selects different card from discard each time
  - Cleared after every EventQueue drain

**Context Validators:**

Cards can validate stable context:

```lua
-- Built-in validators (Utils/ContextValidators.lua)
stableContextValidator = ContextValidators.specificEnemyAlive  -- Chosen enemy must be alive
stableContextValidator = ContextValidators.anyEnemyAlive       -- Any enemy must be alive

-- Custom validator
stableContextValidator = function(world, context, card)
    return context and context.hp > 0 and not context.dead
end
```

If validation fails, card execution is cancelled (logged, not error).

---

### 5. PIPELINE ARCHITECTURE

**Core Principle:** ONE place per mechanic. All game logic lives in pipelines.

#### Key Combat Pipelines

| Pipeline | Purpose | Key Responsibilities |
|----------|---------|---------------------|
| `PlayCard.lua` | Card execution orchestrator | Energy payment, duplication handling, context management, exhaust/discard |
| `ProcessEventQueue.lua` | Event router | Routes events to appropriate handlers (two-tier: SpecialBehaviors + DefaultRoutes) |
| `EventQueueOver.lua` | Queue cleanup | Clear contexts, trigger next card from CardQueue |
| `ResolveCard.lua` | CardQueue processor | Pop and resolve entries from CardQueue |
| `DealDamage.lua` | Attack damage | Strength, weak, vulnerable, block absorption, thorns, Pen Nib, Feed |
| `DealNonAttackDamage.lua` | HP loss effects | Bypasses strength/vulnerable/weak, optionally ignores block |
| `ApplyBlock.lua` | Block gain | Dexterity, frail, blur (carry over block) |
| `ApplyCaps.lua` | Enforce limits | Cap HP to maxHp, block to 999, trigger death checks |
| `Death.lua` | Entity death | Mark dead, trigger Feed healing, Reaper healing |
| `GetCost.lua` | Dynamic cost | Corruption (Skills cost 0), Confusion, Establishment, Blood for Blood |
| `StartTurn.lua` | Turn start | Reset block, draw cards, Echo Form counter, enemy intent selection |
| `EndTurn.lua` | Turn end | Trigger relics, orb passives, Retain mechanics, discard hand, reset flags |
| `EndRound.lua` | Round end | Tick down status effects for all entities (post enemy turns) |
| `DrawCard.lua` | Card draw | Respect cannotDraw, status effects, Evolve (draw on Wound draw) |
| `Discard.lua` | Card discard | Move to discard pile, track cardsDiscardedThisTurn |
| `Exhaust.lua` | Card exhaust | Move to exhausted pile, trigger card.onExhaust hooks |
| `AcquireCard.lua` | Add cards | Add to hand/deck, handle costsZeroThisTurn tag |
| `UsePotion.lua` | Potion usage | Execute potion effect, remove from inventory |

#### Key Map Pipelines

| Pipeline | Purpose |
|----------|---------|
| `Map_ProcessQueue.lua` | Route map events (mirrors ProcessEventQueue for map context) |
| `Map_ChooseNextNode.lua` | Navigate map (validate connections, Winged Boots bypass) |
| `Map_StartCombat.lua` | Initiate combat (set up world.pendingCombat for CLI) |
| `Map_Heal.lua` | Out-of-combat healing (rest sites, events) |
| `Map_ReceiveDamage.lua` | Out-of-combat damage (events, curses) |
| `Map_RemoveCard.lua` | Remove card from masterDeck (shop, events) |
| `Map_UpgradeCard.lua` | Upgrade card in masterDeck (smith, events) |
| `Map_BuildCardPool.lua` | Generate card reward pools (rarity distribution) |

#### Pipeline Pattern

All pipelines follow this structure:

```lua
local MyPipeline = {}

function MyPipeline.execute(world, ...)
    -- 1. Validate preconditions
    if not world or not world.player then
        return
    end

    -- 2. Gather state (check powers, relics, status effects)
    local hasPower = Utils.hasPower(player, "PowerName")
    local statusValue = player.status and player.status.effectName or 0

    -- 3. Perform calculations
    local result = baseValue + modifiers

    -- 4. Apply effects (mutate state)
    player.hp = player.hp + result

    -- 5. Log results
    table.insert(world.log, "Action performed: " .. result)

    -- 6. Queue follow-up events if needed
    world.queue:push({type = "ON_CUSTOM_EFFECT", effect = function() ... end})

    -- 7. Return control token or status
    return {needsContext = false}
end

return MyPipeline
```

**Routing in ProcessEventQueue:**

```lua
-- Tier 1: SpecialBehaviors (complex routing)
if event.type == "ON_DAMAGE" then
    DealDamage.execute(world, event)
    ApplyCaps.execute(world)  -- Auto-call after damage
elseif event.type == "COLLECT_CONTEXT" then
    -- Pause processing if context not collected yet
    ...
end

-- Tier 2: DefaultRoutes (table lookup)
local handler = DefaultRoutes[event.type]
if handler then
    handler.execute(world, event)
end
```

**ApplyCaps Auto-Call:** Special behaviors that modify HP/block automatically call `ApplyCaps.execute()` after processing to enforce caps and trigger death checks.

---

### 6. CARD SYSTEM

**Card Structure** (Data/Cards/*.lua):

```lua
return {
    CardName = {
        -- Identity
        id = "Card_Name",             -- Unique identifier (underscores)
        name = "Card Name",           -- Display name (spaces)
        cost = 1,                     -- Energy cost (or "X")
        type = "ATTACK",              -- "ATTACK" | "SKILL" | "POWER" | "CURSE"
        character = "IRONCLAD",       -- Card class
        rarity = "COMMON",            -- "STARTER" | "COMMON" | "UNCOMMON" | "RARE" | "CURSE"
        description = "Deal 6 damage.",

        -- Stats (context-dependent)
        damage = 6,                   -- Base damage (for attacks)
        block = 5,                    -- Base block (for skills)
        vulnerable = 2,               -- Status stacks to apply

        -- Flags
        exhausts = true,              -- Exhausts after play
        ethereal = true,              -- Discarded at end of turn if not played
        upgraded = false,             -- Upgrade state
        permanentCostZero = 1,        -- Permanent 0 cost (Setup, Forethought)

        -- Special modifiers (checked by pipelines)
        strengthMultiplier = 3,       -- Heavy Blade: Strength applies 3x
        costReductionPerHpLoss = 1,   -- Blood for Blood: -1 cost per HP loss
        poisonMultiplier = 2,         -- Catalyst: Double poison

        -- Context validation
        stableContextValidator = ContextValidators.specificEnemyAlive,

        -- Hooks
        onPlay = function(self, world, player)
            -- Card effect (push events to queue)
        end,

        onUpgrade = function(self)
            -- Modify card properties
        end,

        isPlayable = function(self, world, player)
            -- Custom playability check
            return true  -- or false, "Error message"
        end,

        prePlayAction = function(self, world, player)
            -- Execute before energy payment
        end,

        onExhaust = function(self, world, player)
            -- Trigger when exhausted
        end,

        onEndOfTurn = function(self, world, player)
            -- Trigger at end of turn (for curses)
        end
    }
}
```

**Common Card Patterns:**

1. **Simple Attack** (Strike):
   ```lua
   onPlay = function(self, world, player)
       world.queue:push({
           type = "COLLECT_CONTEXT",
           card = self,
           contextProvider = {type = "enemy", stability = "stable"}
       }, "FIRST")

       world.queue:push({
           type = "ON_DAMAGE",
           attacker = player,
           defender = function() return world.combat.stableContext end,
           card = self
       })
   end
   ```

2. **AOE Attack** (Thunderclap):
   ```lua
   onPlay = function(self, world, player)
       world.queue:push({
           type = "ON_DAMAGE",
           attacker = player,
           defender = "all",  -- AOE damage
           card = self
       })
   end
   ```

3. **X-Cost Card** (Whirlwind):
   ```lua
   cost = "X",  -- String, not number
   onPlay = function(self, world, player)
       for i = 1, self.energySpent do  -- energySpent set by PlayCard
           world.queue:push({type = "ON_DAMAGE", defender = "all", ...})
       end
   end
   ```

4. **Duplication Enabler** (Double Tap):
   ```lua
   onPlay = function(self, world, player)
       player.status = player.status or {}
       player.status.doubleTap = (player.status.doubleTap or 0) + 1
   end
   ```

5. **Card Playing Other Cards** (Omniscience):
   ```lua
   onPlay = function(self, world, player)
       local PlayCard = require("Pipelines.PlayCard")

       -- Request card selection
       world.queue:push({
           type = "COLLECT_CONTEXT",
           contextProvider = {
               type = "cards",
               stability = "temp",
               source = "combat",
               count = {min = 1, max = 1},
               filter = function(_, _, _, candidate)
                   return candidate.state == "DECK"
               end
           }
       }, "FIRST")

       -- Play selected card twice
       world.queue:push({
           type = "ON_CUSTOM_EFFECT",
           effect = function()
               local card = world.combat.tempContext[1]
               card.state = "PROCESSING"
               PlayCard.queueForcedReplay(card, "Omniscience", 1)
               PlayCard.autoExecute(world, player, card, {skipEnergyCost = true})
           end
       })
   end
   ```

**Auto-Loading:** Drop `.lua` file in `Data/Cards/`, return table with card definitions. `Data/cards.lua` uses `LoaderUtils.loadModules()` to auto-load all files.

---

### 7. ENEMY SYSTEM

**Enemy Structure** (Data/Enemies/*.lua):

```lua
return {
    EnemyName = {
        -- Identity & Stats
        id = "EnemyName",
        name = "Display Name",
        hp = 50,
        maxHp = 50,
        block = 0,
        damage = 10,
        description = "Flavor text",

        -- Combat State (initialized by copyEnemyTemplate)
        status = {},              -- Status effects
        powers = {},              -- Reserved (unused)
        dead = false,             -- Death flag

        -- Intent System (AI)
        intents = {
            attack = function(self, world, player)
                world.queue:push({type = "ON_DAMAGE", attacker = self, defender = player, card = self})
            end,
            defend = function(self, world, player)
                world.queue:push({type = "APPLY_BLOCK", target = self, amount = 5})
            end
        },

        selectIntent = function(self, world, player)
            -- AI logic to choose next action
            self.currentIntent = {
                name = "Attack",
                description = "Deal " .. self.damage .. " damage",
                execute = self.intents.attack
            }
        end,

        executeIntent = function(self, world, player)
            -- Execute chosen action
            if self.currentIntent and self.currentIntent.execute then
                self.currentIntent.execute(self, world, player)
            end
        end,

        -- Optional: Reactive behaviors
        ChangeIntentOnDamage = function(self, world, source)
            -- Override intent when damaged (e.g., boss split at 50% HP)
        end
    }
}
```

**Enemy AI Patterns:**

1. **Probabilistic** (Goblin): Random weighted choices
2. **Cyclic** (Acid Slime): Predictable rotation based on turn count
3. **State-Based** (Cultist): First turn ritual, then attack forever
4. **Conditional** (Spike Slime): Mindless attacker

**Enemy Turn Flow:**

```
StartTurn.lua (lines 141-147):
  → For each living enemy: enemy:selectIntent(world, player)

Player Turn:
  → Player plays cards, attacks enemies

EndTurn.lua:
  → (No enemy logic here)

CombatEngine.lua (lines 319-325):
  → For each living enemy: EnemyTakeTurn.execute(world, enemy, player)

EnemyTakeTurn.lua:
  → Reset enemy block to 0
  → Execute enemy.executeIntent() (pushes events to queue)
  → ProcessEventQueue.execute()

EndRound.lua:
  → Tick down status effects for player AND enemies
```

**Special Enemy Mechanics:**

- **Summoning**: Insert new enemies into `world.enemies` array
- **Splitting**: Remove self, insert multiple new enemies (Slime Boss)
- **Reactive**: Use `ChangeIntentOnDamage` to override intent based on HP threshold
- **Multi-phase**: Use state tracking + conditional intent selection

**Important:** Always use `Utils.copyEnemyTemplate()` to create enemy instances. Never use templates directly.

---

### 8. MAP & PROGRESSION SYSTEM

**Map Structure** (Data/Maps/*.lua):

```lua
{
    startNode = "floor1-1",
    nodes = {
        ["node-id"] = {
            id = "node-id",
            type = "combat" | "rest" | "merchant" | "treasure" | "mystery" | "boss",
            difficulty = "normal" | "easy" | "elite" | "boss",
            floor = 1,
            connections = {"next-node-1", "next-node-2"},
            event = "SimpleCombat" | "Campfire" | "Merchant" | ...
        }
    }
}
```

**Map Event Structure** (Data/MapEvents/*.lua):

Events are **state machines** with nodes and options:

```lua
{
    id = "EVENT_ID",
    name = "Display Name",
    tags = {"combat", "rest", "merchant"},
    entryNode = "intro",
    nodes = {
        node_id = {
            text = "Flavor text shown to player",

            onEnter = function(world)
                -- Push events to mapQueue
                MapQueue.push(world, {...})
                return "next_node_id"  -- or nil to stay
            end,

            options = {
                {
                    id = "OPTION_ID",
                    label = "Button text",
                    description = "Tooltip",
                    next = "target_node_id",
                    requires = {gold = 50}
                }
            },  -- or function(world) return {...} end for dynamic

            exit = {result = "complete"}  -- Marks event complete
        }
    }
}
```

**Map Event Flow:**

```
1. MapEngine.startEvent(world, eventId)
   → Set world.currentEvent, world.mapEvent
   → Enter entryNode

2. MapEngine.advanceEvent(world) - main loop:
   WHILE event active:
     a. Get current node
     b. Execute node.onEnter() if present
        → May push to mapQueue
        → May return next node ID
     c. Drain mapQueue (Map_ProcessQueue)
     d. If node has exit marker → Complete event
     e. If node has options → Request selection from player
        → Drain mapQueue again
        → Move to selected option's next node
     f. Continue to next node or break
```

**Map Queue Events:**

- `MAP_CHOOSE_NODE`, `MAP_START_COMBAT`, `MAP_EVENT_COMPLETE`
- `MAP_ACQUIRE_RELIC`, `MAP_LOSE_RELIC`
- `MAP_SPEND_GOLD`, `MAP_HEAL`, `MAP_RECEIVE_DAMAGE`
- `MAP_REMOVE_CARD`, `MAP_UPGRADE_CARD`
- `MAP_COLLECT_CONTEXT`, `MAP_CLEAR_CONTEXT`

**Map-Combat Integration:**

```
Map Event:
  MapQueue.push({type = "MAP_START_COMBAT", enemies = {...}})

Map_StartCombat.lua:
  world.pendingCombat = {enemies, onVictory, onDefeat}
  return {needsCombat = true}

MapCLI.lua (main loop):
  if world.pendingCombat then
    world.enemies = combatConfig.enemies
    StartCombat.execute(world)
    CombatEngine.playGame(world, ...)
    EndCombat.execute(world, victory)
    -- Handle victory/defeat per config
```

**Combat Boundaries:**

- **StartCombat**: Creates `world.combat`, `world.queue`, `world.cardQueue`, deep copies `masterDeck` → `combatDeck`, syncs `currentHp` → `hp`
- **EndCombat**: Syncs `hp` → `currentHp`, discards `combatDeck`, clears combat state

---

### 9. STATUS EFFECTS vs POWERS

**Status Effects** (Data/statuseffects.lua):

- **Temporary effects** with stacks/duration
- Data-driven: defined in `statuseffects.lua` (metadata only)
- Applied via `APPLY_STATUS_EFFECT` events
- Checked by pipelines (DealDamage, ApplyBlock, EndRound)
- Tick down automatically at end of round (EndRound.lua)

**Common Status Effects:**

| Status | Effect | Where Checked |
|--------|--------|---------------|
| `vulnerable` | +50% damage taken (+75% with Paper Phrog) | DealDamage.lua |
| `weak` | -25% damage dealt | DealDamage.lua |
| `frail` | -25% block gain | ApplyBlock.lua |
| `poison` | Lose HP at end of turn | EndRound.lua |
| `strength` | +N damage on attacks | DealDamage.lua |
| `dexterity` | +N block | ApplyBlock.lua |
| `thorns` | Reflect damage to attacker | DealDamage.lua |
| `intangible` | Damage capped at 1 | DealDamage.lua |
| `ritual` | Gain strength at end of turn | EndRound.lua |
| `mark` | Accumulates for Pressure Points | Card: pressurepoints.lua |

**Powers** (Data/Powers/*.lua):

- **Persistent effects** that modify game mechanics
- Defined as Lua files in `Data/Powers/` (separate from cards)
- Applied via `ON_APPLY_POWER` events
- Checked by pipelines using `Utils.hasPower(player, "PowerName")`
- Persist until removed (usually by stacks reaching 0)

**Common Powers:**

| Power | Effect | Where Checked |
|-------|--------|---------------|
| `Corruption` | Skills cost 0, exhaust after play | GetCost.lua, PlayCard.lua |
| `EchoForm` | First N cards each turn play twice | StartTurn.lua, PlayCard.lua |
| `Barricade` | Block doesn't reset at end of turn | EndRound.lua |

**Key Difference:** Status effects tick down automatically. Powers persist until manually removed.

---

### 10. RELICS

**Relic Structure** (Data/Relics/*.lua):

```lua
return {
    RelicName = {
        id = "RelicName",
        name = "Relic Name",
        description = "Effect description",

        -- Event hooks (all optional)
        onCombatStart = function(self, world, player) end,
        onCombatEnd = function(self, world, player) end,
        onCardPlayed = function(self, world, player, card) end,
        onDamageDealt = function(self, world, player, damage, target) end,
        onTurnStart = function(self, world, player) end,
        onTurnEnd = function(self, world, player) end
    }
}
```

**Trigger Points:** Relics are called at specific moments in pipelines:

- `onCombatStart`: StartCombat.lua (line 48-52)
- `onTurnStart`: StartTurn.lua
- `onTurnEnd`: EndTurn.lua (line 51-55)
- `onCardPlayed`: PlayCard.lua
- `onDamageDealt`: DealDamage.lua

**State Tracking:** Relic state persists in `world` (e.g., `world.penNibCounter`, `world.wingedBootsCharges`)

**Examples:**

- **Pen Nib**: Track attack counter in `world.penNibCounter`, check in DealDamage
- **Necronomicon**: Check in PlayCard duplication system
- **Snecko Eye**: Adds Confused status at StartCombat
- **Winged Boots**: Enables bypassing map connections in Map_ChooseNextNode

---

## Common Patterns & Best Practices

### 1. Lazy Evaluation for Context

**WRONG:**
```lua
world.queue:push({
    type = "ON_DAMAGE",
    defender = world.combat.stableContext  -- nil when pushed!
})
```

**CORRECT:**
```lua
world.queue:push({
    type = "ON_DAMAGE",
    defender = function() return world.combat.stableContext end  -- Evaluated later
})
```

### 2. COLLECT_CONTEXT Must Use "FIRST"

```lua
world.queue:push({
    type = "COLLECT_CONTEXT",
    card = self,
    contextProvider = {...}
}, "FIRST")  -- Priority insertion
```

### 3. Checking for Powers

```lua
local Utils = require("utils")
if Utils.hasPower(player, "PowerName") then
    -- Power is active
end
```

### 4. Checking for Relics

```lua
local Utils = require("utils")
if Utils.hasRelic(player, "RelicName") then
    -- Player has relic
end
```

### 5. Checking Status Effects

```lua
if player.status and player.status.vulnerable and player.status.vulnerable > 0 then
    -- Player is vulnerable
end
```

### 6. AOE Damage/Effects

```lua
world.queue:push({
    type = "ON_DAMAGE",
    defender = "all",  -- Hits all enemies
    card = self
})
```

### 7. Always Use copyEnemyTemplate

**WRONG:**
```lua
world.enemies = {Enemies.Goblin}  -- All instances share state!
```

**CORRECT:**
```lua
local Utils = require("utils")
world.enemies = {Utils.copyEnemyTemplate(Enemies.Goblin)}
```

### 8. Event Queue, Not Direct Mutation

**WRONG:**
```lua
player.hp = player.hp - 10  -- Bypasses all modifiers!
```

**CORRECT:**
```lua
world.queue:push({
    type = "ON_NON_ATTACK_DAMAGE",
    source = self,
    target = player,
    amount = 10,
    tags = {"ignoreBlock"}
})
```

---

## File Organization Quick Reference

### When to Modify What

| File | Purpose | Modify When |
|------|---------|-------------|
| `CombatEngine.lua` | Game loop, turn cycle | Adding special mechanics that hijack turn flow (Vault) |
| `Pipelines/PlayCard.lua` | Card execution | New duplication mechanics, card-play hooks |
| `Pipelines/ProcessEventQueue.lua` | Event routing | Adding new event types |
| `Pipelines/DealDamage.lua` | Damage calculation | Effects that modify damage (Strength multipliers, Pen Nib) |
| `Pipelines/ApplyBlock.lua` | Block calculation | Effects that modify block (Dexterity multipliers, Frail) |
| `Pipelines/GetCost.lua` | Cost calculation | Effects that modify costs (Corruption, Confusion) |
| `Pipelines/StartTurn.lua` | Turn start | Start-of-turn triggers (Echo Form counter, draw cards) |
| `Pipelines/EndTurn.lua` | Turn end | End-of-turn triggers (Retain, discard, orb passives) |
| `Pipelines/EndRound.lua` | Round end | Round-end status tick down |
| `Data/statuseffects.lua` | Status metadata | Adding new status effects |
| `Data/Cards/*.lua` | Card definitions | Adding new cards (auto-loaded) |
| `Data/Enemies/*.lua` | Enemy definitions | Adding new enemies (auto-loaded) |
| `Data/MapEvents/*.lua` | Map events | Adding new map encounters/events |
| `utils.lua` | Shared helpers | Utility functions used across files |

---

## Testing

**Test Files:** `tests/`

### Critical Testing Knowledge

#### 1. **HP Capping & Damage Validation**

**Key Insight:** Damage is calculated BEFORE HP is capped to [0, maxHp].

```lua
-- Timeline of a 35-damage attack on 12 HP enemy:
defender.hp = 12 - 35        -- = -23 (UNCAPPED!)
-- Relics/effects see uncapped damage here (e.g., "draw on 30+ damage")
ApplyCaps.execute()          -- Called by ProcessEventQueue
defender.hp = math.max(0, -23) -- = 0 (CAPPED)
```

**Testing Implication:** To verify exact damage amounts, enemies must have enough HP to survive:

```lua
-- ❌ WRONG: Enemy dies, only 12 damage "taken"
enemy.hp = 12
FirePotion deals 15 damage
assert(enemy.hp == initialHp - 15)  -- FAILS: 0 ≠ 12 - 15

-- ✅ CORRECT: Enemy survives, full damage measurable
enemy.hp = 20
FirePotion deals 15 damage
assert(enemy.hp == initialHp - 15)  -- PASSES: 5 == 20 - 15
```

**ApplyCaps Location:** `Pipelines/ApplyCaps.lua:26`
- Auto-called after ON_DAMAGE, ON_NON_ATTACK_DAMAGE, ON_BLOCK, ON_HEAL, ON_STATUS_GAIN
- Enforces: `hp = math.max(0, math.min(hp, maxHp))`
- Also caps block, status effects

#### 2. **Deterministic Testing with NoShuffle**

The deck is shuffled during `StartCombat.lua` and when draw pile empties (`DrawCard.lua`). For deterministic tests:

```lua
world.NoShuffle = true  -- Must be set BEFORE StartCombat.execute()
StartCombat.execute(world)
```

**Why Needed:**
- Tests expecting specific draw order (e.g., "Havoc plays top card")
- Tests using labeled cards for context validation
- Multi-duplication tests where card order matters

**Where Checked:**
- `utils.lua` - `Utils.shuffleDeck(deck, world)` checks `world.NoShuffle`

#### 3. **World.createWorld Parameters**

```lua
World.createWorld({
    id = "IronClad",
    maxHp = 80,
    currentHp = 50,              -- Starting HP (defaults to maxHp)
    maxEnergy = 6,               -- Override default of 3
    energy = 4,                  -- Initial energy (defaults to maxEnergy)
    cards = {card1, card2},      -- Array of cards for masterDeck
    masterPotions = {potion1},   -- Starting potions
    relics = {relic1, relic2},   -- Starting relics
    permanentStrength = 2,       -- Applied at combat start
    orbs = {},                   -- Defect orbs
    maxOrbs = 3                  -- Defect orb slots
})
```

**Fixed Bug:** World.lua now respects `maxEnergy` parameter (was hardcoded to 3 before 2025-11-13).

#### 4. **Context Handling in Tests**

Cards that need targets pause execution and request context. Tests must manually fulfill:

```lua
local function playCardWithAutoContext(world, player, card)
    while true do
        local result = PlayCard.execute(world, player, card)
        if result == true then
            return true  -- Card finished
        end

        -- Handle context request
        if type(result) == "table" and result.needsContext then
            local request = world.combat.contextRequest

            -- Collect context (auto-selects in tests)
            local context = ContextProvider.execute(world, player,
                                                    request.contextProvider,
                                                    request.card)

            -- Store in appropriate location
            if request.stability == "stable" then
                world.combat.stableContext = context
            else
                world.combat.tempContext = context
            end

            world.combat.contextRequest = nil
        elseif result == false then
            -- Card couldn't be played (insufficient energy, etc.)
            break
        end
    end
end
```

**Common Pitfall:** Forgetting `elseif result == false then break` causes infinite loops.

#### 5. **Card Duplication Testing**

When testing duplication mechanics (Double Tap, Echo Form, Burst), ensure:

1. **Enemy has enough HP** to survive all hits
2. **Player has enough energy** to play cards
3. **NoShuffle enabled** if card order matters

```lua
-- Test Double Tap + Echo Form (3 Strikes = 18 damage)
enemy.hp = 20              -- Must survive 3×6 damage
enemy.maxHp = 20
player.status.doubleTap = 1
player.status.echoFormThisTurn = 1

-- After playing Strike:
assert(enemy.hp == 2)      -- 20 - 18 = 2 ✅
```

**Duplication Cancellation:** If target dies mid-duplication chain, remaining duplications are cancelled with log entry `"[Card] canceled - target no longer valid"`. This is EXPECTED behavior.

#### 6. **Card States During Execution**

Cards move through states during play:
- `HAND` → `PROCESSING` (during execution)
- `PROCESSING` → `DISCARD_PILE` (after successful play)
- `PROCESSING` → `EXHAUSTED_PILE` (if exhausts)
- `PROCESSING` → `HAND` (if cancelled due to invalid target)

**Important:** Cancelled cards may remain in `PROCESSING` state. Count both when verifying "cards played":

```lua
local playedCount = countCardsInState(deck, "DISCARD_PILE") +
                   countCardsInState(deck, "PROCESSING")
```

#### 7. **Test Pattern Template**

```lua
local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ContextProvider = require("Pipelines.ContextProvider")

math.randomseed(1337)  -- Deterministic randomness

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

-- Setup
local world = World.createWorld({
    id = "IronClad",
    maxHp = 80,
    maxEnergy = 6,  -- Override if needed
    cards = {copyCard(Cards.Strike), copyCard(Cards.Defend)},
    relics = {}
})

world.enemies = {copyEnemy(Enemies.Goblin)}
world.NoShuffle = true  -- For deterministic tests
StartCombat.execute(world)

-- Modify enemy HP if needed
world.enemies[1].hp = 30
world.enemies[1].maxHp = 30

-- Execute test
local card = findCardById(world.player.combatDeck, "Strike")
playCardWithAutoContext(world, world.player, card)

-- Assertions
assert(world.enemies[1].hp == expectedHp, "Message")
assert(#world.log > 0, "Log should have entries")
```

**Run Tests:**
```bash
lua tests/test_myfeature.lua
```

---

## Tips for Navigating the Code

1. **Find where a mechanic is implemented:** Ctrl+F in `Pipelines/` directory
2. **Find where a card is defined:** Check `Data/Cards/cardname.lua`
3. **Understand turn flow:** Read `CombatEngine.lua` + `StartTurn.lua` + `EndTurn.lua` + `EnemyTakeTurn.lua`
4. **Add new card:** Drop file in `Data/Cards/` - auto-loader handles it
5. **Debug event flow:** Add `table.insert(world.log, "message")` in pipelines
6. **Understand queue system:** Read `Pipelines/EventQueue.lua` + `Pipelines/CardQueue.lua` + `Pipelines/ProcessEventQueue.lua`
7. **Understand map flow:** Read `MapEngine.lua` + `Data/MapEvents/Campfire.lua` (good example)

---

## Architecture Trade-offs

**Pros:**
- ✅ Easy to find logic (Ctrl+F finds THE place)
- ✅ No hidden behavior, no inheritance confusion
- ✅ Easy to add content (just data files, auto-loaded)
- ✅ Queue system handles complex timing correctly
- ✅ Dual-deck architecture prevents combat mutations from polluting permanent deck
- ✅ Event-driven architecture makes all interactions explicit

**Cons:**
- ❌ Modifying mechanics requires touching pipelines
- ❌ No code reuse through inheritance
- ❌ Large pipelines can get complex (DealDamage is 200+ lines)
- ❌ Powers/relics require pipeline modifications to integrate
- ❌ Context system adds complexity (but solves hard problems correctly)

**Philosophy:** This architecture prioritizes **debuggability** and **visibility** over **modularity**. When something breaks, you can find exactly where and why. The centralized pipeline approach makes the codebase easier to understand and modify for a single developer or small team.

---

## Next Steps

For detailed implementation guides, see:

- **`GUIDELINE.md`** - Step-by-step guide for adding cards, enemies, relics, and map events
- **`Docs/ADDING_CARDS_AND_RELICS.md`** - Concrete examples and patterns
- **`Docs/ARCHITECTURE_NOTES.md`** - Design decisions and trade-offs
- **`Docs/centralized-pipeline-architecture.md`** - Deep dive into pipeline architecture
- **`Docs/TODOs.md`** - Known issues and future work

**Happy coding!**
