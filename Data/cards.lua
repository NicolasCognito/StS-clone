-- AUTO-LOADING CARDS AGGREGATOR
-- Automatically loads all card files from Data/Cards/ directory

local LoaderUtils = require("Data.loader_utils")
local moduleName = ...

local Cards = {}
LoaderUtils.loadModules(Cards, "Data.Cards", "Cards", {moduleName = moduleName})

return Cards
