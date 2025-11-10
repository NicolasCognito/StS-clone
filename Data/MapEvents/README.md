# Map Events Overview

Map events unify every map interaction (combat nodes, merchants, question marks, rest sites, treasure, post-combat rewards, etc.) behind a graph of nodes. Each event lives in its own Lua file under `Data/MapEvents/` and returns a table that describes:

- **Metadata** – `id`, `name`, optional tags or requirements (act, min gold, etc.).
- **Graph definition** – an `entryNode` plus a `nodes` table keyed by node id. Each node decides what text/options to show and/or which map pipelines to trigger.
- **Exit semantics** – nodes can mark the event complete so the map engine resumes traversal.

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

## Execution Flow

1. Map node resolved ➜ map engine picks an event and sets `currentNode = entryNode`.
2. It renders the node’s `text`/`options`, collects a player choice, then advances to `option.next`.
3. When a node with an `onEnter` function runs, it can push map-level verbs into `Map_MapQueue` (`Map_ProcessQueue` drains them, similar to combat).
4. Nodes with `exit` end the event; control returns to overworld traversal, which re-enables map movement.

Because nodes are plain Lua tables/functions, they can directly enqueue pipelines or apply bespoke logic while still keeping the overall structure declarative.
