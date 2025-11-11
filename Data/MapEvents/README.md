# Map Events Overview

Map events unify every map interaction (combat nodes, merchants, question marks, rest sites, treasure, post-combat rewards, etc.) behind a graph of nodes. Each event lives in its own Lua file under `Data/MapEvents/` and returns a table that describes:

- **Metadata** – `id`, `name`, optional tags or requirements (act, min gold, etc.).
- **Graph definition** – an `entryNode` plus a `nodes` table keyed by node id. Each node decides what text/options to show and/or which map pipelines to trigger.
- **Exit semantics** – nodes can mark the event complete so the map engine resumes traversal.
- **Direct editing mandate** – per repeated user direction in this repo, MapEvents are the canonical home for overworld logic. Do **not** extract helper pipelines or utility layers that hide behavior. When mechanics change (and they will, often), edit the node directly so the next engineer can trace the exact history of corrections without spelunking through wrappers. See the section “Direct Editing Philosophy” below for the rationale and concrete examples.

## Node Structure

We don’t enforce a strict schema; each node is simply a table with a few conventional fields:

| Field | Description |
| --- | --- |
| `text` | Narrative text shown when the node is entered. |
| `options` | Array of choice tables (id/label/description/requirements/next/contextRequest/etc.). |
| `onEnter(world, eventState)` | Optional function that runs automatically when the node is activated. Use it to enqueue map pipelines (spend gold, heal, etc.) via `Map_MapQueue`. Return the id of the next node to jump to (or `nil` to stay). `eventState` contains transient data collected by the map engine (e.g., `selectedCards` from a prior `contextRequest`). |
| `exit` | Optional metadata (e.g., `{ result = "complete" }`) signaling that the event is over. |

Options commonly include:

```lua
{
    id = "HEAL",
    label = "Heal",
    description = "Lose 35 gold. Heal 25% max HP.",
    requires = { gold = 35 },
    next = "heal"
}
```

Nothing prevents an option from populating extra fields (e.g., `contextRequest` for card selection). The map engine reads these and decides how to collect player input before moving to `next`.

When requesting cards from the permanent deck, pass `contextRequest.environment = "map"` (the ContextProvider defaults to the combat deck otherwise).

If a node needs to actually execute the selection, it can push `MAP_COLLECT_CONTEXT` onto the map queue before any effects, then reference `world.mapEvent.tempContext` (populated by the UI layer) exactly like combat cards reference `world.combat.tempContext`.

Keep event nodes trivial—just like cards, they should push the verbs they need directly without wrapping them in helper functions unless absolutely necessary. The pipelines already provide the abstraction; extra helpers usually just obscure what the node is doing.

## Direct Editing Philosophy

This project has been corrected over and over because contributors tried to “help” by hiding overworld logic behind new helper layers. Every time we do that, understanding rest-site behavior (or any MapEvent) requires chasing multiple files, making bugs harder to spot and slowing down iteration. To prevent yet another round of “why can’t I see what Rest does?”, we have a standing rule:

*All MapEvent behavior belongs in the MapEvent file. Keep it visible, inline, and obvious.*

### What this means in practice

- **No new pipelines for event-specific effects.** Campfire’s Lift/Toke/Dig logic, relic gating, and heal math live right inside `Data/MapEvents/Campfire.lua`. They can still call the shared pipelines (e.g., `MAP_HEAL`, `MAP_REMOVE_CARD`) because those are the verbs, but the decision-making (“if you have Coffee Dripper you can’t Rest”) stays in the node.
- **Configuration belongs on the data objects, not in helper functions.** Relics such as Eternal Feather or Girya expose their tuning values (`healPerChunk`, `maxLifts`) so the Campfire node can read them directly. We don’t make a “FeatherPipeline” to interpret them.
- **When requirements change, edit the node.** If Peace Pipe gains a new limit or Shovel starts consuming charges, open the event file and change the `onEnter`/`options` there. Don’t add “PeacePipeManager.lua” just to toggle a flag.

### Why so strict?

- **Debuggability:** When the player reports, “Rest didn’t heal me,” we want to open one file and see every branch. Inline code makes that possible.
- **Iteration speed:** Rest sites will keep evolving (additional relic hooks, Act 4 keys, future modifiers). Editing the node directly is faster than threading through three helper layers.
- **Historical trace:** Code reviews keep pointing out that we re-learn this lesson. This README now documents the expectation so the reason is discoverable without rehashing it verbally each time.

**TL;DR:** you may call shared pipelines from MapEvents, but do not invent new ones just to hide logic. Inline it, comment it if needed, and keep the behavior obvious.

## Execution Flow

1. Map node resolved ➜ map engine picks an event and sets `currentNode = entryNode`.
2. It renders the node’s `text`/`options`, collects a player choice, then advances to `option.next`.
3. When a node with an `onEnter` function runs, it can push map-level verbs into `Map_MapQueue` (`Map_ProcessQueue` drains them, similar to combat).
4. Nodes with `exit` end the event; control returns to overworld traversal, which re-enables map movement.

Because nodes are plain Lua tables/functions, they can directly enqueue pipelines or apply bespoke logic while still keeping the overall structure declarative.
