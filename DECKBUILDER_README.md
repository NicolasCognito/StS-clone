# Deckbuilder Mode

The Deckbuilder allows you to create custom decks and test them against any enemy in the game.

## Features

### 1. **Character Selection**
- Choose from Ironclad, Silent, or Defect
- Each character has access to their unique card pool

### 2. **Relic Selection (Mode 1/3)**
- Browse all 37 available relics
- Click to add/remove relics from your build
- Selected relics appear in green with a checkmark
- Use mouse wheel to scroll through the list

### 3. **Card Selection (Mode 2/3)**
- Browse all cards for your chosen character
- Filter by type: ALL, ATTACK, SKILL, POWER
- Click cards to add them to your deck
- Current deck shown on the right side
- Use "REMOVE LAST" button to undo mistakes
- Use mouse wheel to scroll through cards

### 4. **Upgrade Selection (Mode 3/3)**
- Review your selected cards
- Click any card to toggle its upgraded status
- Upgraded cards show with "+" suffix and green highlight
- Use mouse wheel to scroll if you have many cards

### 5. **Save Deck**
- Enter a name for your deck (alphanumeric and underscores only)
- Use backspace to edit the name
- Choose:
  - **SAVE & EXIT**: Save and return to main menu
  - **SAVE & TEST**: Save and immediately test against an enemy

### 6. **Test Combat**
- Select a saved deck from the list
- Choose an enemy encounter
- Click "START COMBAT" to begin
- Full combat experience with your custom deck

## Usage

### From Main Menu:

**Option 3: Deckbuilder Mode**
- Creates a new custom deck from scratch
- Goes through all 3 modes (relics → cards → upgrades)

**Option 4: Test Combat**
- Loads a previously saved deck
- Lets you pick any enemy
- Launches directly into combat

### Keyboard Controls:
- **ESC**: Return to main menu (from any mode)
- **Arrow Keys**: Navigate in menus
- **Enter**: Select menu option
- **Backspace**: Delete characters when naming deck
- **Mouse Wheel**: Scroll through lists

## Saved Deck Format

Decks are saved as JSON files in the `Saved_Decks/` folder.

Example format:
```json
{
  "name": "my_custom_deck",
  "character": "IRONCLAD",
  "relics": [
    "Burning_Blood",
    "Pen_Nib"
  ],
  "cards": [
    {
      "id": "Strike",
      "upgraded": false
    },
    {
      "id": "Bash",
      "upgraded": true
    }
  ]
}
```

## File Structure

### New Files:
- `json.lua` - JSON encoder/decoder for Lua
- `DeckSerializer.lua` - Save/load deck configurations
- `UIs/love_gui/DeckbuilderLove.lua` - Main deckbuilder UI
- `Saved_Decks/` - Directory for saved deck JSON files

### Modified Files:
- `main.lua` - Added deckbuilder menu options and integration

## Implementation Details

### DeckSerializer Module

**Functions:**
- `DeckSerializer.save(deckData, filename)` - Save deck to JSON
- `DeckSerializer.load(filename)` - Load deck from JSON
- `DeckSerializer.listDecks()` - Get all saved deck names
- `DeckSerializer.delete(filename)` - Delete a saved deck
- `DeckSerializer.deckDataToMasterDeck(deckData, cardsDatabase)` - Convert saved format to game format
- `DeckSerializer.masterDeckToDeckData(masterDeck, character, relics, name)` - Convert game format to save format

### DeckbuilderLove Module

**Modes:**
1. `character` - Select character class
2. `relics` - Select relics
3. `cards` - Select and add cards
4. `upgrades` - Toggle card upgrades
5. `save` - Name and save deck
6. `testcombat` - Load deck and choose enemy

**Functions:**
- `DeckbuilderLove.init()` - Initialize deckbuilder from scratch
- `DeckbuilderLove.initTestCombat()` - Initialize in test combat mode
- `DeckbuilderLove.draw()` - Render current mode
- `DeckbuilderLove.update(dt)` - Update hover states
- `DeckbuilderLove.mousepressed(x, y, button)` - Handle clicks
- `DeckbuilderLove.wheelmoved(x, y)` - Handle scrolling
- `DeckbuilderLove.textinput(text)` - Handle text input (deck naming)
- `DeckbuilderLove.keypressed(key)` - Handle keyboard (ESC, backspace)

## Example Workflow

1. Launch the game
2. Select "3. Deckbuilder Mode"
3. Choose "Ironclad"
4. Click NEXT
5. Select "Burning Blood" and "Pen Nib" relics
6. Click NEXT
7. Add 5x Strike, 4x Defend, 1x Bash, 1x Offering
8. Click NEXT
9. Upgrade the Bash and one Strike
10. Click "SAVE DECK"
11. Type "aggressive_deck"
12. Click "SAVE & TEST"
13. Select "Goblin" enemy
14. Click "START COMBAT"
15. Play your custom deck!

## Tips

- **Start small**: Build a 10-card deck first to test mechanics
- **Balance upgrades**: Upgraded cards are powerful but you can't upgrade everything
- **Match relics to strategy**: Choose relics that synergize with your deck
- **Test incrementally**: Save and test frequently to iterate on your build
- **Experiment**: Try unusual combinations!

## Troubleshooting

**"No saved decks found!"**
- The `Saved_Decks/` folder is empty
- Create a deck using "Deckbuilder Mode" first

**Deck won't load**
- Check that the JSON file is properly formatted
- Ensure all card IDs match cards in `Data/Cards/`
- Ensure all relic IDs match relics in `Data/Relics/`

**Character mismatch**
- Cards must match the selected character
- IRONCLAD, SILENT, and DEFECT each have unique card pools

## Future Enhancements

Possible future additions:
- Delete/rename saved decks from UI
- Deck templates for common archetypes
- Duplicate existing decks
- Import/export decks to share with others
- Deck statistics (avg cost, type breakdown)
- Multiple enemy encounters (Act bosses, elite fights)
