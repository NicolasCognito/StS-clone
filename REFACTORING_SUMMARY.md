# PlayCard Pipeline Refactoring Summary

**Date:** 2025-11-16
**Branch:** `claude/refactor-playcard-pipeline-015aB3uVEK3cGh2nBQZyiML1`

## Overview

Refactored the PlayCard pipeline to improve clarity, maintainability, and separation of concerns. The refactoring extracts pre-execution logic into a dedicated pipeline and moves supporting functions into helpers.

## Changes Made

### 1. New Pipeline: BeforeCardPlayed.lua

**Purpose:** Handles all pre-execution triggers that run BEFORE a card's `onPlay()` function.

**Extracted Logic:**
- **Statistics tracking** - Counts Powers played (for future relics/mechanics)
- **Storm power** - Channels Lightning when playing Power cards
- **Pen Nib counter** - Increments attack counter (checked in DealAttackDamage)
- **Pain curse** - Deals HP loss from Pain cards in hand
- **Shadow logging** - Enhanced logging for duplication executions

**Why:** Centralizes pre-execution hooks, mirrors AfterCardPlayed pattern, makes it easy to add new pre-play mechanics.

### 2. New Helper Module: PlayCard_Helpers.lua

**Purpose:** Supporting functions for PlayCard to improve code clarity.

**Extracted Functions:**

#### `handleCardCleanup(world, player, card)`
- Determines if card should exhaust or discard
- Exhaust conditions: `card.exhausts = true` OR (Corruption + Skill)
- Queues appropriate event and processes queue
- **Replaced:** 37 lines of inline cleanup logic

#### `calculateEnergySpent(world, player, card, cardCost, options)`
- Handles X-cost calculations
- Applies Chemical X relic bonus
- Supports energy overrides (for auto-play systems)
- **Replaced:** Complex energy calculation logic

#### `formatPlayLog(player, card, options, cardCost)`
- Creates formatted log messages
- Handles various play modes (normal, free, via other cards)
- **Replaced:** Multi-line conditional logging

### 3. Refactored PlayCard.lua

**Before:**
- `executeCardEffect()`: 118 lines with many responsibilities
- `prepareCardPlay()`: 60 lines with embedded logging/cost logic
- Mixed concerns: orchestration + statistics + hooks + cleanup

**After:**
- **Clear delegation pattern**: Calls BeforeCardPlayed, then card.onPlay(), then AfterCardPlayed
- **Helper usage**: Cleanup, cost calculation, and logging delegated to helpers
- **Improved comments**: Crystal-clear step-by-step flow with explanations
- **Better header**: Documents the orchestration architecture

**executeCardEffect() now:**
```lua
1. Check if already initialized (prevent duplicate event pushing)
2. BeforeCardPlayed.execute()  ← Pre-execution hooks
3. card:onPlay()                ← Card's effect
4. Track current executing card
5. Queue AFTER_CARD_PLAYED event
6. Process event queue
7. handleCardCleanup()          ← Discard/exhaust via helper
```

## File Structure

```
Pipelines/
├── PlayCard.lua                    (REFACTORED - orchestrator)
├── PlayCard_Helpers.lua            (NEW - supporting functions)
├── PlayCard_DuplicationHelpers.lua (EXISTING - duplication logic)
├── BeforeCardPlayed.lua            (NEW - pre-execution pipeline)
└── AfterCardPlayed.lua             (EXISTING - post-execution pipeline)
```

## Benefits

1. **Separation of Concerns**
   - PlayCard focuses on orchestration
   - BeforeCardPlayed handles pre-execution hooks
   - AfterCardPlayed handles post-execution hooks
   - Helpers handle supporting tasks

2. **Easier Maintenance**
   - Clear delegation pattern
   - Self-documenting code flow
   - Easy to find where logic lives

3. **Extensibility**
   - Adding new pre-play hooks: Just add to BeforeCardPlayed
   - Adding new post-play hooks: Just add to AfterCardPlayed
   - No need to modify PlayCard's core logic

4. **Consistency**
   - Mirrors existing architecture patterns
   - Follows project's pipeline philosophy
   - Matches AfterCardPlayed pattern

## Compatibility

- **External API unchanged** - All tests should pass without modification
- **Internal behavior preserved** - Same execution order, same logic
- **No breaking changes** - Drop-in replacement

## Documentation Updates

- Updated `Docs/PROJECT_MAP.md`:
  - Added BeforeCardPlayed to pipeline table
  - Updated PlayCard description to reflect delegation
  - Updated Pen Nib documentation with correct flow
  - Updated AfterCardPlayed description

## Testing

Tests cannot be run in this environment (no Lua interpreter), but:
- Code is API-compatible (verified by examining test structure)
- Logic is preserved (moved, not changed)
- Refactoring is straightforward with clear mappings

**Recommended:** Run full test suite after merge:
```bash
lua tests/test_doubletap.lua
lua tests/test_duplication_stacking.lua
lua tests/test_panache.lua
lua tests/test_cardlimits.lua
```

## Migration Guide

For developers adding new features:

### Before (Old Pattern):
```lua
-- To add pre-play logic, modify PlayCard.executeCardEffect()
-- Find the right spot in 118-line function
-- Add logic before card:onPlay()
```

### After (New Pattern):
```lua
-- To add pre-play logic, modify BeforeCardPlayed.execute()
-- Add your hook in the appropriate section
-- Clear comments guide where to add logic
```

## Future Work

This refactoring sets the stage for:
- More pre-play relics/mechanics (easy to add to BeforeCardPlayed)
- Better testing (can test BeforeCardPlayed in isolation)
- Potential further extraction (if prepareCardPlay grows more complex)

## Files Changed

**New:**
- `Pipelines/BeforeCardPlayed.lua` (87 lines)
- `Pipelines/PlayCard_Helpers.lua` (148 lines)
- `REFACTORING_SUMMARY.md` (this file)

**Modified:**
- `Pipelines/PlayCard.lua` (cleaner, better documented)
- `Docs/PROJECT_MAP.md` (updated pipeline table and Pen Nib docs)

**Total Lines:**
- Removed from PlayCard.lua: ~100 lines of complex logic
- Added structure: ~250 lines of clean, documented code
- Net result: Better organized, easier to understand
