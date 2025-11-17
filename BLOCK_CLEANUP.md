# Block Removal & Start-of-Turn Cleanup Report

## Summary
- Block currently resets twice per round (StartTurn and EndRound).
- Barricade only protects the EndRound removal, so StartTurn's unconditional reset ignores it.
- Other temporary flags (costsZeroThisTurn, retainThisTurn, no_draw) are cleared piecemeal across EndTurn/StartTurn rather than in a cohesive "start of turn" phase.

## Details
1. **StartTurn reset** (`Pipelines/StartTurn.lua:488`) sets `player.block = 0` immediately after orb/energy updates. This bypasses Barricade and any future mechanics that should influence block retention.
2. **EndRound reset** (`Pipelines/EndRound.lua:34`) also removes block unless Barricade is active, which is where the logic should live.
3. **Cleanup fragmentation**: temporary card flags and statuses are cleared in multiple places (EndTurn, StartTurn), making it harder to reason about per-turn cleanup responsibilities.

## Recommendation
- Remove the block reset from StartTurn and enforce all block removal (with Barricade exception) inside EndRound.
- Introduce a dedicated "start-of-turn cleanup" section responsible for resetting temporary flags/statuses, so effects like Barricade or future start-of-turn modifiers have a single hook point.
