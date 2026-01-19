# Balatro Mod - Joker Tracker

A simple Balatro mod that displays your current jokers in the console.

## Features

- **Instant Joker Overview**: Press 'J' to see all your current jokers
- **Detailed Information**: Shows joker names, editions (Foil, Holographic, Polychrome, Negative), and special properties
- **Status Tracking**: Displays Eternal, Rental, and Perishable status with remaining rounds
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
2. Press the **'J' key** at any time to display your current jokers
3. Check the console output (press F2 or tilde key `~` to open console in most setups)

### Example Output

```
=== Current Jokers ===
You have 3 joker(s):

1. Joker [Foil] (Eternal)
   ID: j_joker

2. Greedy Joker [Polychrome]
   ID: j_greedy_joker

3. Ice Cream (Perishable: 5 rounds left)
   ID: j_ice_cream

======================
```

## What It Displays

For each joker, the tracker shows:
- **Position** in your joker lineup (1, 2, 3, etc.)
- **Name** of the joker
- **Edition** if applicable (Foil, Holographic, Polychrome, Negative)
- **Eternal** status (cannot be sold or destroyed)
- **Rental** status (costs money each round)
- **Perishable** status with rounds remaining
- **Internal ID** for reference

## Mod Information

- **Mod Name**: Joker Tracker
- **Mod ID**: JokerTracker
- **Version**: 1.0.0
- **Author**: BalatroMod

## Troubleshooting

**Mod not loading?**
- Make sure Steamodded is installed correctly
- Check that the file is in the correct Mods directory
- Restart the game completely

**Console not showing?**
- The console key varies by setup, try F2, tilde (~), or check Lovely Injector documentation
- Make sure you're pressing 'J' during an active run

## Quick Restart Tip

When developing or testing mods, press and hold **'M'** or press **Alt + F5** to quickly restart the game without closing it completely.
