# Balatro Mod - Joker & Hand Tracker

A simple Balatro mod that displays your current jokers, hand cards, and selected hand score in the console.

## Features

- **Instant Overview**: Press 'J' to see all your current jokers AND hand cards
- **Joker Information**: Shows joker names, editions (Foil, Holographic, Polychrome, Negative), and special properties
- **Hand Display**: View all cards in your hand with rank, suit, enhancements, seals, and editions
- **Score Calculation**: See the potential score for your selected hand based on hand type and level
- **Status Tracking**: Displays Eternal, Rental, and Perishable status with remaining rounds
- **Enhancement Detection**: See card enhancements (Bonus, Mult, Wild, Glass, Steel, Stone, Gold, Lucky)
- **Seal Display**: Shows if cards have Red, Blue, Gold, or Purple seals
- **Console Output**: All information is printed to the game console for easy reference

## Installation

### Prerequisites

1. Install [Lovely Injector](https://github.com/ethangreen-dev/lovely-injector)
2. Install [Steamodded](https://github.com/Steamodded/smods)

### Installing the Mod

1. Navigate to your Balatro Mods directory:
   - Windows: `%AppData%/Balatro/Mods`
   - Mac: `~/Library/Application Support/Balatro/Mods`
   - Linux: `~/.local/share/Balatro/Mods`

2. Copy `JokerTracker.lua` into the Mods folder

3. Launch Balatro - the mod will load automatically

## Usage

1. Start a run in Balatro
2. Press the **'J' key** at any time to display your current jokers and hand cards
3. Check the console output (press F2 or tilde key `~` to open console in most setups)

### Example Output

```
You have 3 joker(s):

1. Joker [Foil] (Eternal)
   ID: j_joker

2. Greedy Joker [Polychrome]
   ID: j_greedy_joker

3. Ice Cream (Perishable: 5 rounds left)
   ID: j_ice_cream


--- CARDS IN HAND ---
You have 8 card(s) in hand:

1. A♠ [Steel] [Holographic]
2. K♥ {Gold Seal}
3. Q♦ [Mult] [Foil] (Selected)
4. J♣ (Selected)
5. 10♠ [Glass] (Selected)
6. 9♥ [Bonus] {Red Seal}
7. 8♦
8. 7♣ [Wild]


--- SELECTED HAND SCORE ---

You have 3 card(s) selected:
  1. Q♦
  2. J♣
  3. 10♠

Detected Hand: Straight
Hand Level: 5 (Played 12 times)
Base Chips: 60
Base Mult: 8
Base Score: 480 (60 × 8)

Note: Actual score will differ due to:
  - Individual card chip values
  - Card enhancements (Bonus, Mult, etc.)
  - Joker effects and multipliers
  - Editions (Foil +50 chips, Holo +10 mult, etc.)
  - Seals and other effects

==================================================
```

## What It Displays

### For Each Joker:
- **Position** in your joker lineup (1, 2, 3, etc.)
- **Name** of the joker
- **Edition** if applicable (Foil, Holographic, Polychrome, Negative)
- **Eternal** status (cannot be sold or destroyed)
- **Rental** status (costs money each round)
- **Perishable** status with rounds remaining
- **Internal ID** for reference

### For Each Hand Card:
- **Rank and Suit** (displayed with symbols: ♠♥♦♣)
- **Enhancement** (Bonus, Mult, Wild, Glass, Steel, Stone, Gold, Lucky)
- **Edition** (Foil, Holographic, Polychrome, Negative)
- **Seal** (Red, Blue, Gold, Purple)
- **Selection Status** (if currently selected)

### For Selected Hand Score:
- **Selected Cards** - List of all highlighted/selected cards
- **Hand Type** - The poker hand formed (Pair, Flush, Straight, etc.)
- **Hand Level** - Current level of that hand type
- **Times Played** - How many times you've played this hand
- **Base Chips** - Base chip value for the hand
- **Base Mult** - Base multiplier for the hand
- **Base Score** - Simple calculation (chips × mult)
- **Score Modifiers** - Reminder of factors that affect final score

## Mod Information

- **Mod Name**: Joker & Hand Tracker
- **Mod ID**: JokerTracker
- **Version**: 1.2.0
- **Author**: BalatroMod

## Troubleshooting

**Mod not loading?**
- Make sure Steamodded is installed correctly
- Check that the file is in the correct Mods directory
- Restart the game completely

**Console not showing?**
- The console key varies by setup, try F2, tilde (~), or check Lovely Injector documentation
- Make sure you're pressing 'J' during an active run

**Hand cards not displaying?**
- Make sure you have cards in your hand
- The tracker will show "Your hand is empty" if you've played all cards

**Score calculation not working?**
- Score calculation requires you to be in an active hand with plays remaining
- Select your cards first, then press 'J' to see the evaluated hand
- If hand detection fails, the mod will still show which cards are selected

## Quick Restart Tip

When developing or testing mods, press and hold **'M'** or press **Alt + F5** to quickly restart the game without closing it completely.
