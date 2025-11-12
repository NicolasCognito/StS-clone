High pririty:
-DEATH: Make death pipeline, FIFO from both DealDamage if less than 0, remove Death handling from CombatEngine. Consider if we want to remove killed enemies from Combat.
-MISSING CONTEXT (stableContext): DONE - Validation system implemented with ContextValidators
-POTIONS: Very similar to cards, but potions! Don't have masterDeck/combatDeck separation, taken directly from persistent masterPotion table in the world, added there as well.
-ENEMIES: Ensure each enemy defined in lua script with logic - they should have possible intents as functions, as well as selector function to choose one,
    and hook it right after player gains energy for a turn.
    Consider making Encounters table, that lists individual enemies, and could be referenced by the map.

VERY LOW PRIORITY!!!
-VAULT: Ensure it cleans CardQueue from everything pending. Consider if it should clear rest of EventQueue as well, if relevant, and where.
-CONTEXT: Ensure correct behavior of stableContext vs tempContext - stable presists for duplicated copies, temp is recollected each time.
    I believe it works as intended thanks to a little boilerplate in cards themselves with clear_context calls after collecting wrong context.
-ECHO: Ensure that Echo works with a quirk specified in documentation. If Echo copy is NOT played, stack is restored.
-INSUFFICIENT TEMPCONTEXT (POSSIBLE SOLUTION - NEEDS INVESTIGATION): Handle when tempContext provides less than minimum expected entities (e.g., Dagger Throw with empty hand).
    Investigate current behavior first - cards are tables, might already handle gracefully.
    POSSIBLE modes if needed:
        Mode 1 (default): Pop events from queue until CLEAR_CONTEXT event, optionally call card.onInsufficientContext(world)
        Mode 2 (lenient): Proceed with whatever context was collected
    Would be specified in contextProvider config: insufficientMode = "cancel" or "proceed" 