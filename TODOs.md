High pririty:
-DEATH: Make death pipeline, FIFO from both DealDamage if less than 0, remove Death handling from CombatEngine.
-MISSING CONTEXT: If stable/temp context doesn't provide expected value, handle it gracefully - 
    clear queue entirely if card doesn't override clear with custom logic.
        Example #1: Enemy died before duplication triggered 
            (dead enemies aren't removed from combat, but stableContext should be invalidated, so entire card is canceled by default)
        Example #2: Cards context collection provided less than minimal expected number of entities (E.g. Dagger Throw hadn't had a card to discard)
-POTIONS: Very similar to cards, but potions! Don't have masterDeck/combatDeck separation, taken directly from persistent masterPotion table in the world.
-ENEMIES: Ensure each enemy defined in lua script with logic - they should have possible intents as functions, as well as selector function to choose one,
    and hook it right after player gains energy for a turn. 
-SHUFFLE/ORDERING: For now deck has consistent ordering. We need to decide how we determine top card of the deck etc., considering Lua quirks.
-MERCHANT: He doesn't show card names, it's obviously incorrect.
-MAP: Sometimes has strange cancel option, investigate what it is.

VERY LOW PRIORITY!!!
-VAULT: Ensure it cleans CardQueue from everything pending. Consider if it should clear rest of EventQueue as well, if relevant, and where. 
-CONTEXT: Ensure correct behavior of stableContext vs tempContext - stable presists for duplicated copies, temp is recollected each time. 
    I believe it works as intended thanks to a little boilerplate in cards themselves with clear_context calls after collecting wrong context.
-ECHO: Ensure that Echo works with a quirk specified in documentation. If Echo copy is NOT played, stack is restored. 