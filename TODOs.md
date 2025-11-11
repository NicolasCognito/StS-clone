-DEATH: Make death pipeline, FIFO from both DealDamage if less than 0, remove Death handling from CombatEngine.
-MISSING CONTEXT: If stable/temp context doesn't provide expected value, handle it gracefully - clear queue entirely if card doesn't override clear with custom logic.
    Example #1: Enemy died before duplication triggered
    Example #2: Cards context collection provided less than minimal expected number of entities (E.g. Dagger Throw hadn't had a card to discard)
-POTIONS: Very similar to cards, but potions! Don't have masterDeck/combatDeck separation, taken directly from persistent masterPotion table in the world.
-VAULT: Ensure it cleans CardQueue from everything pending. Consider if it should clear rest of EventQueue as well, if relevant, and where. 
-CONTEXT: Ensure correct behavior of stableContext vs tempContext - stable presists for duplicated copies, temp is recollected each time. 
    I believe it works thanks to a little boilerplate in cards themselves with clear_context calls, analyze if it's ok.
-ECHO: Ensure that Echo works with a little quirk specified in documentation. 