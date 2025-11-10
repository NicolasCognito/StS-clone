-- AUTO-LOADING CARDS AGGREGATOR
-- Automatically loads all card files from Data/Cards/ directory

local Cards = {}

local cardFiles = {
    "strike",
    "defend",
    "bash",
    "heavyblade",
    "flamebarrier",
    "bloodletting",
    "bloodforblood",
    "infernalblade",
    "corruption",
    "catalyst",
    "discovery",
    "grandfinale",
    "whirlwind",
    "skewer",
    "intimidate",
    "thunderclap",
    "daggerthrow",
    "doubletap",
    "headbutt"
}

for _, fileName in ipairs(cardFiles) do
    local card = require("Data.Cards." .. fileName)
    for key, value in pairs(card) do
        Cards[key] = value
    end
end

return Cards
