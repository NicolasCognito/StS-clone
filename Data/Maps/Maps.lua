-- MAPS DATA
-- Map structures for different acts
-- Each map is a graph of nodes with connections

local Maps = {}

-- Simple test map - 3 floors with branching paths
Maps.TestMap = {
    startNode = "floor1-1",
    nodes = {
        -- Floor 1
        ["floor1-1"] = {
            id = "floor1-1",
            type = "combat",
            floor = 1,
            connections = {"floor1-2", "floor1-3"}
        },
        ["floor1-2"] = {
            id = "floor1-2",
            type = "combat",
            floor = 1,
            connections = {"floor2-1"}
        },
        ["floor1-3"] = {
            id = "floor1-3",
            type = "rest",
            floor = 1,
            connections = {"floor2-1", "floor2-2"}
        },

        -- Floor 2
        ["floor2-1"] = {
            id = "floor2-1",
            type = "elite",
            floor = 2,
            connections = {"floor2-3"}
        },
        ["floor2-2"] = {
            id = "floor2-2",
            type = "merchant",
            floor = 2,
            connections = {"floor2-3"}
        },
        ["floor2-3"] = {
            id = "floor2-3",
            type = "treasure",
            floor = 2,
            connections = {"floor3-1"}
        },

        -- Floor 3
        ["floor3-1"] = {
            id = "floor3-1",
            type = "boss",
            floor = 3,
            connections = {}
        }
    }
}

return Maps
