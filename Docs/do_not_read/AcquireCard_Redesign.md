# AcquireCard Pipeline Redesign

**Date:** 2025-11-14

> **NOTE:** This document has been integrated into the main documentation:
> - **Quick Reference:** See `PROJECT_MAP.md` Section 6.5 "Card Generation with AcquireCard"
> - **Implementation Guide:** See `GUIDELINE.md` Example 8 "AcquireCard Pipeline (Card Generation)"
> - This file is kept for comprehensive reference but is not required reading for developers

## Overview

The AcquireCard pipeline has been redesigned to support flexible card acquisition with filtering, multiple destinations, and advanced options. This document explains the new API and provides usage examples.

---

## New API

```lua
AcquireCard.execute(world, player, cardSource, options)
```

### Parameters

#### `cardSource`

Can be either:

1. **Direct card template** (e.g., `Cards.Shiv`, `Cards.Wound`)
2. **Filter specification:**
   ```lua
   {
       filter = function(world, card)
           return card.type == "ATTACK" and card.character == "IRONCLAD"
       end,
       count = N  -- How many unique cards to select from pool
   }
   ```

#### `options` (table)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `destination` | string | `"HAND"` | Where to place the card:<br/>- `"HAND"`: Add to hand<br/>- `"DISCARD_PILE"`: Add to discard pile<br/>- `"DECK"`: Insert into draw pile at position<br/>- Custom string: Set card.state to that value (e.g., `"DRAFT"`, `"NIGHTMARE"`) |
| `position` | string\|number | `"random"` | For `destination="DECK"` only:<br/>- `"random"`: Insert at random index<br/>- `"top"`: Insert at top of deck<br/>- `"bottom"`: Insert at bottom<br/>- number: Insert at specific index |
| `tags` | array | `{}` | Tags to apply as `card.tagName = 1`:<br/>- `"costsZeroThisTurn"`<br/>- `"costsZeroThisCombat"`<br/>- `"retain"`<br/>- etc. |
| `targetDeck` | string | auto | `"combat"` or `"master"`<br/>Defaults to `"combat"` if in combat, else `"master"` |
| `count` | number | `1` | How many copies of EACH selected card |
| `skipMasterReality` | boolean | `false` | (For modders) Skip Master Reality auto-upgrade |
| `forceShuffleDeck` | boolean | `false` | (For modders) Do full shuffle when destination="DECK" |

### Returns

Array of created card instances (even if count=1)

---

## Key Concepts

### 1. Insert vs Shuffle

When `destination="DECK"`, the card is **inserted at a position** without doing a full shuffle. This matches Slay the Spire behavior where "shuffle into draw pile" means "insert at random position."

- `position="random"` (default): Pick random index in [1, deckSize+1]
- `position="top"`: Insert at index 1 (next draw)
- `position="bottom"`: Insert at end
- `position=N`: Insert at specific index

A full shuffle only happens if `forceShuffleDeck=true` (for modders).

### 2. Master Reality Integration

The pipeline automatically checks for Master Reality power and upgrades created cards unless `skipMasterReality=true`.

### 3. Filter-Based Selection

When using a filter specification, the pipeline:
1. Builds a pool of all cards matching the filter
2. Randomly selects `count` unique cards from the pool
3. Creates copies of each selected card

This enables clean implementations of cards like:
- **Infernal Blade**: 1 random Attack
- **Discovery**: 3 different random cards to choose from
- **White Noise**: 1 random Power

---

## Usage Examples

### Example 1: Simple Card to Hand (Blade Dance)

Add 3 Shivs to hand:

```lua
local AcquireCard = require("Pipelines.AcquireCard")

AcquireCard.execute(world, player, Cards.Shiv, {
    destination = "HAND",
    count = 3
})
```

### Example 2: Random Card with Tag (Infernal Blade)

Add 1 random Attack to hand, costs 0 this turn:

```lua
AcquireCard.execute(world, player, {
    filter = function(w, card)
        return card.type == "ATTACK" and card.character == player.id
    end,
    count = 1
}, {
    destination = "HAND",
    tags = {"costsZeroThisTurn"}
})
```

### Example 3: Card to Discard Pile (Anger, Immolate)

Add Burn to discard pile:

```lua
AcquireCard.execute(world, player, Cards.Burn, {
    destination = "DISCARD_PILE"
})
```

### Example 4: Insert into Deck (Wild Strike, Evaluate)

Insert Wound at random position in draw pile:

```lua
AcquireCard.execute(world, player, Cards.Wound, {
    destination = "DECK",
    position = "random"
})
```

### Example 5: Multiple Random Cards (Discovery)

Generate 3 different random cards for selection:

```lua
AcquireCard.execute(world, player, {
    filter = function(w, card)
        return card.character and card.rarity ~= "CURSE"
    end,
    count = 3
}, {
    destination = "DRAFT"
})
```

### Example 6: Custom State (Nightmare)

Create 3 copies with NIGHTMARE state:

```lua
AcquireCard.execute(world, player, selectedCard, {
    destination = "NIGHTMARE",
    count = 3
})
```

### Example 7: To Master Deck (Card Rewards)

Add card to permanent deck:

```lua
AcquireCard.execute(world, player, Cards.Strike, {
    targetDeck = "master"
})
```

### Example 8: Deck Position Control

Insert Wound at top of deck, Dazed at bottom:

```lua
AcquireCard.execute(world, player, Cards.Wound, {
    destination = "DECK",
    position = "top"
})

AcquireCard.execute(world, player, Cards.Dazed, {
    destination = "DECK",
    position = "bottom"
})
```

---

## Event-Based Usage (ON_ACQUIRE_CARD)

For cards that push events to the queue, use:

```lua
world.queue:push({
    type = "ON_ACQUIRE_CARD",
    player = player,
    cardSource = cardTemplateOrFilter,
    options = optionsTable
})
```

**Examples:**

```lua
-- Direct template
world.queue:push({
    type = "ON_ACQUIRE_CARD",
    player = player,
    cardSource = Cards.Shiv,
    options = {
        destination = "HAND",
        count = 3
    }
})

-- Filter-based
world.queue:push({
    type = "ON_ACQUIRE_CARD",
    player = player,
    cardSource = {
        filter = function(w, c) return c.type == "ATTACK" end,
        count = 1
    },
    options = {
        destination = "HAND",
        tags = {"costsZeroThisTurn"}
    }
})
```

---

## Common Card Patterns

### Shiv Generation (Silent)

```lua
-- Blade Dance: 3 Shivs
AcquireCard.execute(world, player, Cards.Shiv, {
    destination = "HAND",
    count = 3
})

-- Cloak and Dagger: 1-2 Shivs
AcquireCard.execute(world, player, Cards.Shiv, {
    destination = "HAND",
    count = self.upgraded and 2 or 1
})
```

### Status Creation

```lua
-- Wild Strike: Wound to deck
AcquireCard.execute(world, player, Cards.Wound, {
    destination = "DECK",
    position = "random"
})

-- Power Through: 2 Wounds to hand
AcquireCard.execute(world, player, Cards.Wound, {
    destination = "HAND",
    count = 2
})

-- Immolate: Burn to discard
AcquireCard.execute(world, player, Cards.Burn, {
    destination = "DISCARD_PILE"
})
```

### Random Generation

```lua
-- Infernal Blade: random Attack, 0-cost
AcquireCard.execute(world, player, {
    filter = function(w, card)
        return card.type == "ATTACK" and card.character == player.id
    end,
    count = 1
}, {
    destination = "HAND",
    tags = {"costsZeroThisTurn"}
})

-- White Noise: random Power, 0-cost
AcquireCard.execute(world, player, {
    filter = function(w, card)
        return card.type == "POWER" and card.character == player.id
    end,
    count = 1
}, {
    destination = "HAND",
    tags = {"costsZeroThisTurn"}
})
```

### Discover Pattern

```lua
-- Foreign Influence: choose 1 of 3 Attacks from any color
local created = AcquireCard.execute(world, player, {
    filter = function(w, card)
        return card.type == "ATTACK"
    end,
    count = 3
}, {
    destination = "DRAFT"
})

-- Then use context collection to choose one
-- (See Discovery card implementation for full pattern)
```

---

## Implementation Notes

### Card Copying

Uses `Utils.deepCopyCard()` or `Utils.copyCardTemplate()` for proper card copying, avoiding shallow copy issues.

### Master Reality

Automatically checks for Master Reality power and upgrades created cards:

```lua
if Utils.hasPower(player, "MasterReality") then
    if not newCard.upgraded and type(newCard.onUpgrade) == "function" then
        newCard:onUpgrade()
        newCard.upgraded = true
    end
end
```

### Logging

Appropriate log messages for each destination type:
- HAND: "Added [Card] to hand (costs 0 this turn)"
- DISCARD_PILE: "Added [Card] to discard pile"
- DECK: "Inserted [Card] into draw pile"
- Custom: "Added [Card] (state: [STATE])"

---

## Migration Guide

### Old Code
```lua
local newCard = {}
for k, v in pairs(cardTemplate) do
    newCard[k] = v
end
newCard.state = "HAND"
newCard.costsZeroThisTurn = 1
table.insert(player.combatDeck, newCard)
```

### New Code
```lua
AcquireCard.execute(world, player, cardTemplate, {
    destination = "HAND",
    tags = {"costsZeroThisTurn"}
})
```

### Benefits
- Automatic Master Reality integration
- Consistent card copying
- Proper state management
- Better logging
- Support for complex destinations

---

## Testing

See `tests/test_acquirecard.lua` for comprehensive test coverage of:
- Simple card to hand
- Cards with tags
- Discard pile destination
- Insert into deck at various positions
- Multiple random cards with filters
- Custom states
- Master Reality integration
- Master deck vs combat deck

---

## Future Extensions

Potential future additions (for modders):

1. **Relic hooks**: `onAcquireCard(world, player, card)` triggers
2. **Card pool modifiers**: Prismatic Shard integration
3. **Acquisition sources**: Track where cards came from (shop, reward, card effect)
4. **Scoped filters**: Easy presets like "attacks from my class" or "common skills"

---

## Summary

The redesigned AcquireCard pipeline provides:

✅ **Flexible destinations** - HAND, DISCARD_PILE, DECK, or custom states
✅ **Filter-based selection** - Random cards from filtered pools
✅ **Insert semantics** - Place in draw pile without full shuffle
✅ **Tag system** - Apply modifiers like costsZeroThisTurn
✅ **Master Reality integration** - Automatic upgrade support
✅ **Clean card implementations** - Less boilerplate, more declarative

This makes implementing card generation effects much cleaner and more consistent across the codebase.
