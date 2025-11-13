High pririty:
-DEATH: Make death pipeline, FIFO from both DealAttackDamage if less than 0, remove Death handling from CombatEngine. Consider if we want to remove killed enemies from Combat.
-MISSING CONTEXT (stableContext): DONE - Validation system implemented with ContextValidators
-POTIONS: Very similar to cards, but potions! Don't have masterDeck/combatDeck separation, taken directly from persistent masterPotion table in the world, added there as well.
-ENEMIES: Ensure each enemy defined in lua script with logic - they should have possible intents as functions, as well as selector function to choose one,
    and hook it right after player gains energy for a turn.
    Consider making Encounters table, that lists individual enemies, and could be referenced by the map.

VERY LOW PRIORITY!!!
-VAULT: Ensure it cleans CardQueue from everything pending. Consider if it should clear rest of EventQueue as well, if relevant, and where.
-CONTEXT: DONE - stableContext persists for duplicated copies, tempContext is recollected each time. Works as intended with clear_context calls.
-ECHO: Ensure that Echo works with a quirk specified in documentation. If Echo copy is NOT played, stack is restored.
-INSUFFICIENT TEMPCONTEXT (POSSIBLE SOLUTION - NEEDS INVESTIGATION): Handle when tempContext provides less than minimum expected entities (e.g., Dagger Throw with empty hand).
    Investigate current behavior first - cards are tables, might already handle gracefully.
    POSSIBLE modes if needed:
        Mode 1 (default): Pop events from queue until CLEAR_CONTEXT event, optionally call card.onInsufficientContext(world)
        Mode 2 (lenient): Proceed with whatever context was collected
    Would be specified in contextProvider config: insufficientMode = "cancel" or "proceed"

===================================
STANCE SYSTEM IMPLEMENTATION (Watcher)
===================================

COMPLETED:
✅ Mantra status effect + Divinity trigger (ApplyStatusEffect.lua)
✅ Mental Fortress status effect + card
✅ Flurry of Blows card + ChangeStance trigger
✅ Inner Peace card
✅ Fear No Evil card
✅ Enemy intentType="ATTACK" tags (all enemies)

TODO - SIMPLE STANCE-ENTERING CARDS:
- [ ] Vigilance (Skill: Block + enter Calm) - STARTER
- [ ] Eruption (Attack: Damage + enter Wrath) - STARTER
- [ ] Tranquility (Retain Skill: Enter Calm, Exhausts)
- [ ] Crescendo (Retain Skill: Enter Wrath, Exhausts)

TODO - STANCE-EXITING CARDS:
- [ ] Empty Body (Skill: Block, exit stance)
- [ ] Empty Fist (Attack: Damage, exit stance)
- [ ] Empty Mind (Skill: Exit stance, draw cards)

TODO - STANCE-CONDITIONAL CARDS:
- [ ] Halt (Skill: Block, extra Block if in Wrath)
- [ ] Indignation (Skill: Enter Wrath OR apply Vulnerable if already in Wrath)

TODO - MANTRA CARDS:
- [ ] Prostrate (Skill: Mantra + Block)
- [ ] Pray (Skill: Mantra + shuffle Insight into draw)
- [ ] Worship (Retain Skill: Gain chunk of Mantra)
- [ ] Brilliance (Attack: Damage + bonus damage = total Mantra gained this combat)
- [ ] Blasphemy (Retain Skill: Enter Divinity immediately, die at end of next turn)

TODO - SPECIAL MECHANICS:
- [ ] Meditate (Skill: Pull cards from discard, make them Retain, enter Calm, end turn)
- [ ] Simmering Fury (Skill: At start of next turn, enter Wrath and draw cards)
- [ ] Tantrum (Attack: Multi-hit, enter Wrath, shuffle itself back into draw pile)

TODO - POWERS (as status effects):
- [ ] Like Water status + card (At end of turn, if in Calm, gain Block)
- [ ] Rushdown status + card (Whenever you enter Wrath, draw 2 cards)
- [ ] Devotion status + card (At start of turn, gain Mantra)

TODO - RELICS:
- [ ] Damaru (Common, Watcher): At start of turn, gain 1 Mantra
- [ ] Teardrop Locket (Uncommon, Watcher): Start each combat in Calm
- [ ] Violet Lotus (Boss, Watcher): Exiting Calm gives +3 energy instead of +2

TODO - SUPPORT CARDS (referenced by other cards):
- [ ] Insight card (for Pray card to shuffle into deck) 