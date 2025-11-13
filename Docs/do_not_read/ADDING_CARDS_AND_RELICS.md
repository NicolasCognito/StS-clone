# Adding Cards and Relics

This guide explains how to add new cards and relics to the Slay the Spire clone following the **centralized pipeline architecture**.

## Table of Contents
- [Philosophy](#philosophy)
- [Adding Cards](#adding-cards)
- [Adding Relics](#adding-relics)
- [Pipeline vs Delta Functions](#pipeline-vs-delta-functions)
- [Common Patterns](#common-patterns)
- [Examples](#examples)

---

## Philosophy

This codebase follows a **centralized pipeline architecture**:

- **Entities are 95% data** - Cards and relics are mostly data structures
- **One pipeline per game verb** - All logic for an action lives in ONE place
- **Hardcoded special cases** - Use direct if-statements, not polymorphism
- **Queue-based events** - Cards push events, pipelines process them

**Key Principle:** Don't scatter logic across 300 card classes. Put it in the pipeline where it belongs.

---

## Adding Cards

### Step 1: Define the Card Data

Add your card to `Data/Cards/Cards.lua`:

```lua
NewCard = {
    id = "New_Card",
    name = "New Card",
    cost = 1,
    type = "ATTACK",  -- or "SKILL", "POWER", "CURSE"
    character = "IRONCLAD",  -- or "SILENT", "DEFECT", "WATCHER", "COLORLESS", "CURSE"
    rarity = "COMMON",  -- or "UNCOMMON", "RARE", "STARTER", "CURSE"
    damage = 10,      -- optional, for attack cards
    block = 5,        -- optional, for defense cards
    Targeted = 1,     -- 1 if requires target, 0 if self/AOE
    description = "Deal 10 damage. Gain 5 block.",

    onPlay = function(self, world, player, target)
        -- Push events to queue (see below)
    end,

    onUpgrade = function(self)
        -- Modify card parameters
        self.damage = 14
        self.description = "Deal 14 damage. Gain 5 block."
    end
}
```

### Step 2: Push Events in onPlay

Cards should **declare intent** by pushing events. Don't implement damage/block logic directly:

```lua
onPlay = function(self, world, player, target)
    -- Deal damage
    world.queue:push({
        type = "ON_ATTACK_DAMAGE",
        attacker = player,
        defender = target,
        card = self
    })

    -- Gain block
    world.queue:push({
        type = "ON_BLOCK",
        target = player,
        card = self
    })

    -- Apply status effect
    world.queue:push({
        type = "ON_STATUS_GAIN",
        target = target,
        effectType = "Vulnerable",
        amount = 2,
        source = self
    })
end
```

### Step 3: Available Event Types

| Event Type | Purpose | Required Fields |
|------------|---------|----------------|
| `ON_ATTACK_DAMAGE` | Attack damage (affected by Strength/Vulnerable) | `attacker`, `defender`, `card` |
| `ON_NON_ATTACK_DAMAGE` | Non-attack damage (NOT affected by Strength/Vulnerable) | `source`, `target`, `amount`, optional `tags` |
| `ON_BLOCK` | Gain block | `target`, `card` |
| `ON_HEAL` | Heal HP | `target`, `amount` or `relic` |
| `ON_STATUS_GAIN` | Apply status effect | `target`, `effectType`, `amount`, `source` |

### Step 4: Event Tags

Some events support **tags** for special behavior:

```lua
world.queue:push({
    type = "ON_NON_ATTACK_DAMAGE",
    source = nil,
    target = player,
    amount = 3,
    tags = {"ignoreBlock"}  -- Bypasses block (for HP loss effects)
})
```

**Available Tags:**
- `ignoreBlock` - Damage bypasses block (used for HP loss like Bloodletting)

### Step 5: Card Classes and Rarity

All cards should have a `character` field to indicate which character class they belong to:

**Character Classes:**
- `IRONCLAD` - Red character, strength-based cards
- `SILENT` - Green character, poison and combo cards
- `DEFECT` - Blue character, orb and frost cards
- `WATCHER` - Purple character, stance and calm cards
- `COLORLESS` - Available to all characters (e.g., Discovery, Burst, Omniscience)
- `CURSE` - Curse cards that hinder the player

**Rarity Levels:**
- `STARTER` - Starting deck cards (Strike, Defend, Bash)
- `COMMON` - Frequently appears in card rewards
- `UNCOMMON` - Less common, more powerful
- `RARE` - Powerful cards, rare to find
- `CURSE` - Curse cards only

**Example Card Classes:**

```lua
-- IRONCLAD common attack
Strike = {
    id = "Strike",
    name = "Strike",
    cost = 1,
    type = "ATTACK",
    character = "IRONCLAD",
    rarity = "STARTER",
    damage = 6,
    description = "Deal 6 damage."
}

-- COLORLESS uncommon skill
Discovery = {
    id = "Discovery",
    name = "Discovery",
    cost = 1,
    type = "SKILL",
    character = "COLORLESS",
    rarity = "COMMON",
    description = "Choose 1 of 3 random cards to add to your hand."
}

-- CURSE
Pain = {
    id = "Pain",
    name = "Pain",
    cost = -2,  -- Unplayable
    type = "CURSE",
    character = "CURSE",
    rarity = "CURSE",
    description = "Unplayable. When you exhaust this card, lose 1 HP."
}
```

### Step 6: Add to Deck (for testing)

In `main.lua`, add your card to the starting deck:

```lua
table.insert(deck, copyCard(Cards.NewCard))
```

---

## Adding Relics

### Passive Relics (Effect in Pipeline)

For relics that modify **existing mechanics** (like Paper Phrog modifying Vulnerable):

```lua
PaperPhrog = {
    id = "Paper_Phrog",
    name = "Paper Phrog",
    rarity = "UNCOMMON",
    description = "Enemies with Vulnerable take 75% more damage rather than 50%.",
    -- No delta functions needed!
    -- Effect is hardcoded in DealAttackDamage pipeline
}
```

Then add hardcoded check in the relevant pipeline (e.g., `Pipelines/DealAttackDamage.lua`):

```lua
-- Check if attacker has Paper Phrog relic
if attacker.relics then
    for _, relic in ipairs(attacker.relics) do
        if relic.id == "Paper_Phrog" then
            vulnerableMultiplier = 1.75  -- Paper Phrog: 75%
            break
        end
    end
end
```

### Active Relics (Delta Functions)

For relics that trigger **on events** (like Burning Blood healing at end of combat):

```lua
BurningBlood = {
    id = "Burning_Blood",
    name = "Burning Blood",
    rarity = "STARTER",
    description = "At the end of combat, heal 6 HP.",
    healAmount = 6,

    onEndCombat = function(self, world, player)
        world.queue:push({
            type = "ON_HEAL",
            target = player,
            relic = self
        })
    end
}
```

**Available Delta Functions:**
- `onEndCombat(self, world, player)` - Triggered when player ends turn

### Conditional Relics (Dynamic Checks)

For relics with **conditional effects** (like Red Skull: +3 Strength when HP ≤ 50%):

```lua
RedSkull = {
    id = "Red_Skull",
    name = "Red Skull",
    rarity = "COMMON",
    description = "While your HP is at or below 50%, you have 3 additional Strength.",
    -- No delta functions needed!
}
```

Add check in `DealAttackDamage.lua`:

```lua
-- Calculate effective strength (base + conditional bonuses)
local effectiveStrength = attacker.status and attacker.status.strength or 0

-- Check for Red Skull relic: +3 Strength when HP <= 50%
if attacker.relics then
    for _, relic in ipairs(attacker.relics) do
        if relic.id == "Red_Skull" then
            if attacker.hp <= math.floor(attacker.maxHp * 0.5) then
                effectiveStrength = effectiveStrength + 3
            end
            break
        end
    end
end
```

**Why this is better than the real game:** No bugs with Artifact, no double-stacking, no invisible debuffs!

---

## Pipeline vs Delta Functions

### Use Delta Functions When:
- ✅ Simple state changes (gain energy, draw cards)
- ✅ Triggered effects with clear timing (onEndCombat)
- ✅ The logic is unique to this card/relic

### Use Pipelines When:
- ✅ Complex interactions (damage calculation, block absorption)
- ✅ Affects multiple cards (Strength, Vulnerable)
- ✅ Needs to interact with other systems (relics, status effects)

### Examples:

**Delta Function** (Bloodletting gaining energy):
```lua
-- Simple enough to do directly in onPlay
player.energy = player.energy + self.energyGain
table.insert(world.log, player.id .. " gained " .. self.energyGain .. " energy")
```

**Pipeline** (Bloodletting losing HP):
```lua
-- Complex: needs to check block, apply tags, log
world.queue:push({
    type = "ON_NON_ATTACK_DAMAGE",
    source = nil,
    target = player,
    amount = self.hpLoss,
    tags = {"ignoreBlock"}
})
```

---

## Common Patterns

### Pattern 1: Basic Attack Card

```lua
Strike = {
    id = "Strike",
    name = "Strike",
    cost = 1,
    type = "ATTACK",
    damage = 6,
    Targeted = 1,
    description = "Deal 6 damage.",

    onPlay = function(self, world, player, target)
        world.queue:push({
            type = "ON_ATTACK_DAMAGE",
            attacker = player,
            defender = target,
            card = self
        })
    end
}
```

### Pattern 2: Block + Status Effect

```lua
Bash = {
    id = "Bash",
    name = "Bash",
    cost = 1,
    type = "ATTACK",
    damage = 8,
    Targeted = 1,
    description = "Deal 8 damage. Apply 2 Vulnerable.",

    onPlay = function(self, world, player, target)
        world.queue:push({
            type = "ON_ATTACK_DAMAGE",
            attacker = player,
            defender = target,
            card = self
        })
        world.queue:push({
            type = "ON_STATUS_GAIN",
            target = target,
            effectType = "Vulnerable",
            amount = 2,
            source = self
        })
    end
}
```

### Pattern 3: Multi-Effect Skill

```lua
FlameBarrier = {
    id = "Flame_Barrier",
    name = "Flame Barrier",
    cost = 2,
    type = "SKILL",
    block = 12,
    thorns = 4,
    Targeted = 0,
    description = "Gain 12 block. Gain 4 Thorns.",

    onPlay = function(self, world, player, target)
        world.queue:push({
            type = "ON_BLOCK",
            target = player,
            card = self
        })
        world.queue:push({
            type = "ON_STATUS_GAIN",
            target = player,
            effectType = "Thorns",
            amount = self.thorns,
            source = self
        })
    end
}
```

### Pattern 4: HP Loss for Benefit

```lua
Bloodletting = {
    id = "Bloodletting",
    name = "Bloodletting",
    cost = 0,
    type = "SKILL",
    hpLoss = 3,
    energyGain = 2,
    Targeted = 0,
    description = "Lose 3 HP. Gain 2 Energy.",

    onPlay = function(self, world, player, target)
        -- HP loss ignores block
        world.queue:push({
            type = "ON_NON_ATTACK_DAMAGE",
            source = nil,
            target = player,
            amount = self.hpLoss,
            tags = {"ignoreBlock"}
        })

        -- Energy gain is simple enough to do directly
        player.energy = player.energy + self.energyGain
        table.insert(world.log, player.id .. " gained " .. self.energyGain .. " energy")
    end
}
```

### Pattern 5: Strength-Scaling Attack

```lua
HeavyBlade = {
    id = "Heavy_Blade",
    name = "Heavy Blade",
    cost = 2,
    type = "ATTACK",
    damage = 14,
    strengthMultiplier = 3,  -- Special flag checked in DealAttackDamage pipeline
    Targeted = 1,
    description = "Deal 14 damage. Strength affects this card 3 times.",

    onPlay = function(self, world, player, target)
        world.queue:push({
            type = "ON_ATTACK_DAMAGE",
            attacker = player,
            defender = target,
            card = self
        })
    end
}
```

---

## Examples

### Example 1: Adding "Armaments" (Gain 5 Block, Upgrade a random card)

```lua
Armaments = {
    id = "Armaments",
    name = "Armaments",
    cost = 1,
    type = "SKILL",
    block = 5,
    Targeted = 0,
    description = "Gain 5 block. Upgrade a random card in your hand.",

    onPlay = function(self, world, player, target)
        -- Gain block
        world.queue:push({
            type = "ON_BLOCK",
            target = player,
            card = self
        })

        -- Upgrade random card (simple logic, do directly)
        if #player.hand > 0 then
            local randomCard = player.hand[math.random(#player.hand)]
            if randomCard.onUpgrade then
                randomCard:onUpgrade()
                table.insert(world.log, randomCard.name .. " was upgraded!")
            end
        end
    end
}
```

### Example 2: Adding "Runic Pyramid" (Don't discard hand at end of turn)

This requires modifying the `EndTurn` pipeline:

```lua
-- In Pipelines/EndTurn.lua:

-- Check for Runic Pyramid before discarding
local hasRunicPyramid = false
if player.relics then
    for _, relic in ipairs(player.relics) do
        if relic.id == "Runic_Pyramid" then
            hasRunicPyramid = true
            break
        end
    end
end

-- Discard remaining hand (unless Runic Pyramid)
if not hasRunicPyramid then
    for _, card in ipairs(player.hand) do
        table.insert(player.discard, card)
    end
    player.hand = {}
end
```

Then add the relic:

```lua
RunicPyramid = {
    id = "Runic_Pyramid",
    name = "Runic Pyramid",
    rarity = "BOSS",
    description = "At the end of your turn, you do not discard your hand.",
    -- Effect is hardcoded in EndTurn pipeline
}
```

---

## Key Takeaways

1. **Cards are mostly data** - Keep onPlay functions simple, just push events
2. **Pipelines contain the logic** - All damage/block/status logic lives in pipelines
3. **Hardcode special cases** - Don't abstract, just add if-statements in pipelines
4. **Use tags for variations** - Use `tags` array for special behaviors like ignoreBlock
5. **Delta functions for simple effects** - Energy gain, card draw, etc. can be direct
6. **One place per mechanic** - All Vulnerable logic in DealAttackDamage, all block logic in ApplyBlock

**The architecture is simple by design.** If you find yourself creating abstract base classes or complex inheritance hierarchies, you're doing it wrong. Just add the logic where it belongs and move on.
