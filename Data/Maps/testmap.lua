-- TEST MAP DEFINITION
-- Simple branching structure for demonstrating overworld traversal

local TestMap = {
    TestMap = {
        startNode = "floor1-1",
        nodes = {
            ["floor1-1"] = {
                id = "floor1-1",
                type = "combat",
                difficulty = "normal",
                floor = 1,
                connections = {"floor2-1", "floor2-2"},
                event = "TheCleric"
            },

            ["floor2-1"] = {
                id = "floor2-1",
                type = "combat",
                difficulty = "elite",
                floor = 2,
                connections = {"floor3-1", "floor3-2"},
                event = "TheCleric"
            },

            ["floor2-2"] = {
                id = "floor2-2",
                type = "rest",
                floor = 2,
                connections = {"floor3-1", "floor3-2"},
                event = "Campfire"
            },

            ["floor3-1"] = {
                id = "floor3-1",
                type = "merchant",
                floor = 3,
                connections = {"floor4-1"},
                event = "Merchant"
            },

            ["floor3-2"] = {
                id = "floor3-2",
                type = "treasure",
                floor = 3,
                connections = {"floor4-1"},
                event = "TheCleric"
            },

            ["floor4-1"] = {
                id = "floor4-1",
                type = "combat",
                difficulty = "boss",
                floor = 4,
                connections = {},
                event = "TheCleric"
            }
        }
    }
}

return TestMap

