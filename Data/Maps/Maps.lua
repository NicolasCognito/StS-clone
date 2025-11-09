-- MAPS DATA
-- Map structures for different acts
-- Each map is a graph of nodes with connections
--
-- Node types: combat, rest, merchant, treasure, event
-- Combat nodes have difficulty: normal, elite, boss

local Maps = {}

-- Simple test map - 3 floors with branching paths
-- Connections only go to next floor (no same-floor connections)
Maps.TestMap = {
    startNode = "floor1-1",
    nodes = {
        -- Floor 1
        ["floor1-1"] = {
            id = "floor1-1",
            type = "combat",
            difficulty = "normal",
            floor = 1,
            connections = {"floor2-1", "floor2-2"}  -- Only connects to floor 2
        },

        -- Floor 2
        ["floor2-1"] = {
            id = "floor2-1",
            type = "combat",
            difficulty = "elite",
            floor = 2,
            connections = {"floor3-1", "floor3-2"}  -- Only connects to floor 3
        },
        ["floor2-2"] = {
            id = "floor2-2",
            type = "rest",
            floor = 2,
            connections = {"floor3-1", "floor3-2"}  -- Only connects to floor 3
        },

        -- Floor 3
        ["floor3-1"] = {
            id = "floor3-1",
            type = "merchant",
            floor = 3,
            connections = {"floor4-1"}  -- Only connects to floor 4
        },
        ["floor3-2"] = {
            id = "floor3-2",
            type = "treasure",
            floor = 3,
            connections = {"floor4-1"}  -- Only connects to floor 4
        },

        -- Floor 4 (Boss)
        ["floor4-1"] = {
            id = "floor4-1",
            type = "combat",
            difficulty = "boss",
            floor = 4,
            connections = {}  -- End of map
        }
    }
}

return Maps
