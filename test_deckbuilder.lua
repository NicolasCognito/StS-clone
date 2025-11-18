-- Test script for DeckSerializer functionality

local DeckSerializer = require("DeckSerializer")
local JSON = require("json")

print("=== Testing DeckSerializer ===")

-- Test 1: JSON encoding/decoding
print("\n1. Testing JSON encode/decode...")
local testData = {
    name = "Test Deck",
    character = "IRONCLAD",
    relics = {"Burning_Blood", "Vajra"},
    cards = {
        {id = "Strike", upgraded = false},
        {id = "Defend", upgraded = true},
        {id = "Bash", upgraded = false}
    }
}

local encoded = JSON.encode(testData)
print("Encoded JSON:")
print(encoded)

local decoded = JSON.decode(encoded)
print("\nDecoded back:")
print("  Name: " .. decoded.name)
print("  Character: " .. decoded.character)
print("  Relics: " .. #decoded.relics)
print("  Cards: " .. #decoded.cards)

-- Test 2: Save deck
print("\n2. Testing save deck...")
local success, err = pcall(function()
    DeckSerializer.save(testData, "test_deck")
    print("✓ Deck saved successfully to Saved_Decks/test_deck.json")
end)

if not success then
    print("✗ Failed to save: " .. tostring(err))
end

-- Test 3: List decks
print("\n3. Testing list decks...")
local decks = DeckSerializer.listDecks()
print("Found " .. #decks .. " saved deck(s):")
for i, deckName in ipairs(decks) do
    print("  " .. i .. ". " .. deckName)
end

-- Test 4: Load deck
print("\n4. Testing load deck...")
success, err = pcall(function()
    local loaded = DeckSerializer.load("test_deck")
    print("✓ Deck loaded successfully:")
    print("  Name: " .. loaded.name)
    print("  Character: " .. loaded.character)
    print("  Relics: " .. table.concat(loaded.relics, ", "))
    print("  Cards: " .. #loaded.cards .. " cards")
end)

if not success then
    print("✗ Failed to load: " .. tostring(err))
end

-- Test 5: Convert to masterDeck format
print("\n5. Testing deck conversion...")
local Cards = require("Data.cards")
success, err = pcall(function()
    local deckData = DeckSerializer.load("test_deck")
    local masterDeck = DeckSerializer.deckDataToMasterDeck(deckData, Cards)
    print("✓ Converted to masterDeck:")
    print("  Total cards: " .. #masterDeck)
    for i, card in ipairs(masterDeck) do
        local upgradedStr = card.upgraded and "+" or ""
        print("    " .. i .. ". " .. card.name .. upgradedStr)
    end
end)

if not success then
    print("✗ Failed to convert: " .. tostring(err))
end

print("\n=== All tests completed ===")
