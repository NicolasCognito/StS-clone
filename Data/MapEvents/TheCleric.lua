local MapQueue = require("Pipelines.Map_MapQueue")

return {
    TheCleric = {
        id = "THE_CLERIC",
        name = "The Cleric",
        tags = {"mystery"},
        requirements = {
            acts = {1},
            minGold = 35
        },
        entryNode = "intro",
        nodes = {
            intro = {
                text = "Ahead you spot a bombastic cleric surrounded by shimmering light. \"My services are of the highest quality!\" he booms.",
                options = {
                    {
                        id = "HEAL",
                        label = "Heal",
                        description = "Lose 35 gold. Heal 25% of your max HP.",
                        requires = { gold = 35 },
                        next = "heal"
                    },
                    {
                        id = "PURIFY",
                        label = "Purify",
                        description = "Lose 50 gold. Remove a card from your deck.",
                        requires = { gold = 50 },
                        next = "purify_remove"
                    },
                    {
                        id = "LEAVE",
                        label = "Leave",
                        description = "Politely decline and continue on your way.",
                        next = "exit"
                    }
                }
            },

            heal = {
                onEnter = function(world)
                    MapQueue.push(world, { type = "MAP_SPEND_GOLD", amount = 35 })
                    MapQueue.push(world, { type = "MAP_HEAL_PERCENT", percent = 0.25 })
                    MapQueue.push(world, { type = "MAP_EVENT_COMPLETE", result = "heal" })
                    return "exit"
                end
            },

            purify_remove = {
                onEnter = function(world)
                    MapQueue.push(world, {
                        type = "MAP_COLLECT_CONTEXT",
                        contextProvider = {
                            type = "cards",
                            source = "master",
                            environment = "map",
                            stability = "temp",
                            count = {min = 1, max = 1}
                        }
                    }, "FIRST")

                    MapQueue.push(world, { type = "MAP_SPEND_GOLD", amount = 50 })
                    MapQueue.push(world, {
                        type = "MAP_REMOVE_CARD",
                        source = "master",
                        card = function()
                            local ctx = world.mapEvent and world.mapEvent.tempContext
                            return ctx and ctx[1]
                        end
                    })
                    MapQueue.push(world, { type = "MAP_CLEAR_CONTEXT", target = "temp" })
                    MapQueue.push(world, { type = "MAP_EVENT_COMPLETE", result = "purify" })
                    return "exit"
                end
            },

            exit = {
                exit = { result = "complete" }
            }
        }
    }
}
