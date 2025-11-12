# Project Map - Slay the Spire Clone

This document explains the architecture, relationships between components, and how to navigate/modify the codebase.

## Architecture Philosophy

This codebase follows a **Centralized Pipeline Architecture**:
- **Cards are data**, not OOP classes - they generate events, don't execute logic
- **All game logic lives in pipelines** - ONE place per mechanic (damage, block, status effects, etc.)
- **Queue-based event system** - Cards push events to queues, pipelines process them
- **No inheritance/polymorphism** - Extensible through visibility (Ctrl+F), not modularity
- **Auto-loading** - Drop new files in `Data/Cards/`, `Data/Powers/`, etc. and they load automatically

## Directory Structure

```
StS-clone/
├── CombatEngine.lua          # Main game loop, handles player input and turn flow
├── Pipelines/                # All game logic lives here
│   ├── PlayCard.lua          # Card playing orchestration
│   ├── ProcessEventQueue.lua # Routes events to appropriate handlers
│   ├── StartTurn.lua         # Player turn initialization
│   ├── EndTurn.lua           # Player turn cleanup
│   ├── EnemyTakeTurn.lua     # Enemy turn execution
│   ├── DealDamage.lua        # Damage calculation (weak, vulnerable, thorns, etc.)
│   ├── ApplyBlock.lua        # Block calculation (dexterity, frail, etc.)
│   ├── ApplyStatusEffect.lua # Status effect application
│   ├── DrawCard.lua          # Card drawing logic
│   └── ...                   # Other specialized pipelines
├── Data/                     # Game content definitions
│   ├── cards.lua             # Auto-loader for cards
│   ├── Cards/                # Individual card definitions
│   │   ├── strike.lua
│   │   ├── defend.lua
│   │   └── ...
│   ├── powers.lua            # Auto-loader for powers
│   ├── Powers/               # Individual power definitions
│   ├── relics.lua            # Auto-loader for relics
│   ├── Relics/               # Individual relic definitions
│   ├── enemies.lua           # Enemy definitions
│   ├── statuseffects.lua     # Status effect metadata
│   └── loader_utils.lua      # Shared auto-loading utilities
├── tests/                    # Test files
└── utils.lua                 # Shared utility functions
```

## Key Systems

### 1. Combat Flow (CombatEngine.lua)

**Main Game Loop:**
1. Display game state (HP, energy, hand, enemies)
2. Get player input (play card / end turn)
3. Execute action via pipelines
4. Check win/lose conditions
5. Loop

**Turn Cycle:**
```
Player Turn → EndTurn → Enemy Turns (loop) → StartTurn → Player Turn
     ↓            ↓            ↓                  ↓
Play cards   Discard,    Reset block,        Reset block,
or end       tick down   execute intent,     draw cards
             player      tick down enemy
             status      status
```

### 2. Card System

**Card Structure** (Data/Cards/*.lua):
```lua
return {
    CardName = {
        id = "CardName",
        name = "Card Name",
        cost = 1,
        type = "ATTACK" | "SKILL" | "POWER",
        rarity = "COMMON" | "UNCOMMON" | "RARE",
        -- Card-specific properties
        damage = 6,
        block = 5,

        onPlay = function(self, world, player, target)
            -- Push events to queue (don't execute directly!)
            world.queue:push({
                type = "ON_DAMAGE",
                defender = target,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.damage = 9
        end
    }
}
```

**Auto-Loading:**
- Drop new `.lua` file in `Data/Cards/`
- File must return a table with card definitions
- `Data/cards.lua` automatically loads all files via `LoaderUtils.loadModules()`

**Card Properties:**
- `id`: Unique identifier
- `name`: Display name
- `cost`: Energy cost (modified by GetCost.lua pipeline)
- `type`: ATTACK, SKILL, or POWER
- `damage`: Base damage (if attack)
- `block`: Base block (if defensive)
- `onPlay`: Function that pushes events to queue
- `onUpgrade`: Function that modifies card properties

### 3. Event Queue System

**Two Queues:**
1. **EventQueue** (FIFO) - Game events: damage, block, status effects
2. **CardQueue** (LIFO) - Card execution stack (handles duplications)

**Event Flow:**
```
Card.onPlay()
  ↓
Push event to world.queue
  ↓
ProcessEventQueue.execute()
  ↓
Route to appropriate pipeline:
  - ON_DAMAGE → DealDamage.lua
  - ON_BLOCK → ApplyBlock.lua
  - ON_STATUS_GAIN → ApplyStatusEffect.lua
  - ON_APPLY_POWER → ApplyPower.lua
  - COLLECT_CONTEXT → Pause for user input (target selection)
  - etc.
```

**Event Types:**
- `ON_DAMAGE`: Deal damage to target
- `ON_BLOCK`: Gain block
- `ON_STATUS_GAIN`: Apply status effect (vulnerable, weak, etc.)
- `ON_APPLY_POWER`: Apply power (ongoing buff/debuff)
- `ON_DISCARD`: Discard card
- `ON_EXHAUST`: Exhaust card
- `COLLECT_CONTEXT`: Request user input (enemy target, card selection)
- `AFTER_CARD_PLAYED`: Trigger after-play effects

### 4. Context System (Target Selection)

**For cards requiring targets:**
```lua
-- Step 1: Request context (enemy target, card selection, etc.)
world.queue:push({
    type = "COLLECT_CONTEXT",
    card = self,
    contextProvider = {
        type = "enemy",      -- or "cards"
        stability = "stable" -- or "temp"
    }
}, "FIRST")  -- Insert at front of queue

-- Step 2: Use context in damage event
world.queue:push({
    type = "ON_DAMAGE",
    defender = function() return world.combat.stableContext end,
    card = self
})
```

**Context Stability:**
- **stable**: Persists across duplications (enemy target for Strike)
- **temp**: Re-collected each duplication (Headbutt's card selection)

### 5. Pipeline System

**Key Pipelines:**

| Pipeline | Purpose | Key Mechanics |
|----------|---------|---------------|
| `PlayCard.lua` | Orchestrates card playing | Cost payment, duplications (Double Tap, Burst), Necronomicon |
| `ProcessEventQueue.lua` | Routes events to handlers | Central event dispatcher |
| `DealDamage.lua` | Damage calculation | Strength, weak, vulnerable, block, thorns |
| `ApplyBlock.lua` | Block calculation | Dexterity, frail |
| `StartTurn.lua` | Turn initialization | Reset block, draw cards, Echo Form counter |
| `EndTurn.lua` | Turn cleanup | Tick status, Retain mechanics, discard hand |
| `EnemyTakeTurn.lua` | Enemy actions | Reset enemy block, execute intent, tick enemy status |
| `GetCost.lua` | Dynamic cost calculation | Corruption, Confusion, Establishment |

**Pipeline Pattern:**
```lua
local MyPipeline = {}

function MyPipeline.execute(world, ...)
    -- 1. Check preconditions
    -- 2. Perform calculations (check powers, relics, status effects)
    -- 3. Apply effects
    -- 4. Log results
    -- 5. Queue follow-up events if needed
end

return MyPipeline
```

### 6. Status Effects vs Powers

**Status Effects** (Data/statuseffects.lua):
- **Temporary effects** with stacks/duration
- Examples: vulnerable, weak, frail, poison, thorns, strength, dexterity
- Defined in `statuseffects.lua` (metadata only)
- Applied via `ApplyStatusEffect.lua` pipeline
- **Checked by pipelines** when calculating damage/block

**Powers** (Data/Powers/*.lua):
- **Persistent effects** that modify game mechanics
- Examples: Corruption (Skills cost 0), Echo Form (duplicate cards)
- Defined as Lua files in `Data/Powers/`
- Applied via `ApplyPower.lua` pipeline
- **Checked by pipelines** using `Utils.hasPower(player, "PowerName")`

**Key Difference:**
- Status effects tick down automatically at end of turn
- Powers persist until removed (usually by stacks reaching 0)

### 7. Relics

**Relic Structure** (Data/Relics/*.lua):
```lua
return {
    RelicName = {
        id = "RelicName",
        name = "Relic Name",
        description = "Effect description",

        -- Event hooks (all optional)
        onCombatStart = function(self, world, player) end,
        onEndCombat = function(self, world, player) end,
        onCardPlayed = function(self, world, player, card) end,
        onDamageDealt = function(self, world, player, damage, target) end,
        -- etc.
    }
}
```

**Trigger Points:**
- Relics trigger in pipelines at specific moments
- Example: `Pen Nib` checks `penNibCounter` in `DealDamage.lua`
- Example: `Necronomicon` is checked in `PlayCard.lua` for duplication

### 8. Turn Flow Details

**Player Turn Start** (StartTurn.lua):
1. Clear turn flags (`cannotDraw`, `necronomiconThisTurn`)
2. Set Echo Form counter from power stacks
3. **Reset player block to 0**
4. Draw cards (5 base + Snecko Eye bonus)

**Player Turn End** (EndTurn.lua):
1. Trigger relic `onEndCombat` effects
2. Process effect queue
3. **Tick down player status effects** (vulnerable--, weak--)
4. Handle Retain mechanics (don't discard retained cards)
5. Discard non-retained hand cards
6. Clear temporary flags (`costsZeroThisTurn`)
7. Reset combat trackers (`cardsDiscardedThisTurn`)
8. Reset energy to `maxEnergy`

**Enemy Turn** (EnemyTakeTurn.lua):
1. **Reset enemy block to 0**
2. Execute enemy intent (attack, defend, buff, etc.)
3. Process effect queue
4. **Tick down enemy status effects** (vulnerable--, weak--)

**Round Concept:**
- No explicit "end of round" phase (yet)
- Status effects tick at end of each character's turn individually
- Future "end of round" effects would go between enemy turns and StartTurn

## How to Add New Content

### Adding a Card

1. Create file: `Data/Cards/mycardname.lua`
2. Define card structure (see Card System above)
3. Auto-loader picks it up automatically - no imports needed!
4. Test in `tests/` or via CombatEngine

**Example:**
```lua
return {
    MyCard = {
        id = "MyCard",
        name = "My Card",
        cost = 1,
        type = "SKILL",
        description = "Apply 2 Vulnerable.",

        onPlay = function(self, world, player, target)
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = function() return world.combat.stableContext end,
                effectType = "Vulnerable",
                amount = 2,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Apply 2 Vulnerable. (Upgraded)"
        end
    }
}
```

### Adding a Power

1. Create file: `Data/Powers/mypowername.lua`
2. Define power structure
3. Modify relevant pipelines to check for power using `Utils.hasPower()`

**Example:**
```lua
return {
    MyPower = {
        id = "MyPower",
        name = "My Power",
        description = "At the start of your turn, gain 1 Energy."
    }
}
```

Then in `StartTurn.lua`:
```lua
if Utils.hasPower(player, "MyPower") then
    player.energy = player.energy + 1
end
```

### Adding a Relic

1. Create file: `Data/Relics/myrelicname.lua`
2. Define relic with event hooks
3. Pipelines automatically trigger relic hooks at appropriate moments

### Adding a Status Effect

1. Add entry to `Data/statuseffects.lua`
2. Implement trigger logic in relevant pipelines (StartTurn, EndTurn, EnemyTakeTurn, etc.)

## Important Files Quick Reference

| File | Purpose | When to Modify |
|------|---------|----------------|
| `CombatEngine.lua` | Game loop, turn cycle | Adding special mechanics that hijack turn flow (like Vault) |
| `Pipelines/PlayCard.lua` | Card playing | Adding new duplication mechanics or card-play hooks |
| `Pipelines/ProcessEventQueue.lua` | Event routing | Adding new event types |
| `Pipelines/DealDamage.lua` | Damage calculation | Adding effects that modify damage (powers, relics) |
| `Pipelines/ApplyBlock.lua` | Block calculation | Adding effects that modify block |
| `Pipelines/GetCost.lua` | Cost calculation | Adding effects that modify card costs |
| `Pipelines/StartTurn.lua` | Turn start effects | Adding start-of-turn triggers |
| `Pipelines/EndTurn.lua` | Turn end effects | Adding end-of-turn triggers |
| `Data/statuseffects.lua` | Status metadata | Adding new status effects |
| `utils.lua` | Shared helpers | Adding utility functions used across files |

## Common Patterns

### Checking for Powers
```lua
local Utils = require("utils")
if Utils.hasPower(player, "PowerName") then
    -- do something
end
```

### Checking for Relics
```lua
for _, relic in ipairs(player.relics) do
    if relic.id == "RelicName" then
        -- do something
    end
end
```

### Checking Status Effects
```lua
if player.status and player.status.vulnerable and player.status.vulnerable > 0 then
    -- player is vulnerable
end
```

### AOE (All Enemies)
```lua
world.queue:push({
    type = "ON_DAMAGE",
    defender = "all",  -- Special keyword for AOE
    card = self
})
```

### Card Duplication Flags
```lua
-- Double Tap: next N attacks play twice
player.status.doubleTap = (player.status.doubleTap or 0) + 1

-- Burst: next N skills play twice
player.status.burst = (player.status.burst or 0) + 1

-- Echo Form: first N cards each turn play twice
player.status.echoFormThisTurn = stacks
```

## Testing

Tests live in `tests/` directory. Each test:
1. Creates a world state
2. Sets up player, enemies, deck
3. Simulates combat actions
4. Asserts expected outcomes

Run tests via Lua runtime:
```bash
lua tests/test_myfeature.lua
```

## Tips for Navigating the Code

1. **Find where a mechanic is implemented:** Ctrl+F in `Pipelines/` directory
2. **Find where a card is defined:** Check `Data/Cards/cardname.lua`
3. **Understand turn flow:** Read `CombatEngine.lua:116-290` and the three turn pipelines
4. **Add new card:** Just drop a file in `Data/Cards/` - auto-loader handles it
5. **Debug event flow:** Add `table.insert(world.log, "message")` in pipelines

## Architecture Trade-offs

**Pros:**
- ✅ Easy to find logic (Ctrl+F finds THE place)
- ✅ No hidden behavior, no inheritance confusion
- ✅ Easy to add cards (just data files)
- ✅ Queue system handles complex timing correctly

**Cons:**
- ❌ Modifying mechanics requires touching pipelines
- ❌ No code reuse through inheritance
- ❌ Large pipelines can get complex
- ❌ Powers/relics require pipeline modifications to integrate

This architecture prioritizes **debuggability** and **visibility** over **modularity**.
