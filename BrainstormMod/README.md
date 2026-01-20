![Brainstorm-mod logo](Assets/BrainstormLogo.jpg)
--
## Requirements
- [Lovely](https://github.com/ethangreen-dev/lovely-injector) injector -- Get it here: https://github.com/ethangreen-dev/lovely-injector/releases

## Installation

1. Install [Lovely](https://github.com/ethangreen-dev/lovely-injector) and follow the manual installation instructions.

### Windows

2. Download the [latest release](https://github.com/OceanRamen/Brainstorm/releases/) of Brainstorm.
3. Unzip the file, and place it in `.../%appdata%/balatro/mods` -- Make sure the Mod's directory name is 'Brainstorm' [^1]
4. Reload the game to activate the mod.

### Macos

2. Go to your Balatro Mods dir `/Users/$USER/Library/Application Support/Balatro/Mods`.
3. Clone the Brainstorm repo `git clone https://github.com/OceanRamen/Brainstorm.git`.
4. Check that the new directory's name is "Brainstorm".
5. Reload the game to activate the mod.

## Features
### Save-States
Brainstorm has the capability to save up to 5 save-states through the use of in-game key binds. 
> To create a save-state: Hold `z + 1-5`
> To load a save-state:	Hold `x + 1-5`

Each number from 0 - 5 corresponds to a save slot. To overwrite an old save, simply create a new save-state in it's slot. 

### Fast Rerolling
Brainstorm allows for super-fast rerolling through the use of an in-game key bind. 
> To fast-roll:	Press `Ctrl + t`

### Auto-Rerolling
Brainstorm can automatically reroll for parameters as specified by the user.
You can edit the Auto-Reroll parameters in the Brainstorm in-game settings page.
> To Auto-Reroll:	Press `Ctrl + a`

#### Custom Filter: Blueprint/Brainstorm + Money Joker
A custom filter has been added that searches for seeds where you can obtain both:
- **Blueprint** OR **Brainstorm** joker
- **AND** one of these money-generating jokers:
  - Mail-in Rebate
  - Business Card
  - Cloud 9
  - Rocket
  - Midas Mask
  - Gift Card
  - Reserved Parking
  - Golden Joker
  - Trading Card

The filter checks the shop jokers in **Ante 1 and Ante 2** to find seeds where both types of jokers are available early in the run.

**Implementation:** This filter uses the exact RNG seed strings reverse-engineered from Balatro's code (based on the [Brainstorm-Rerolled](https://github.com/ABGamma/Brainstorm-Rerolled) Immolate C++ implementation), ensuring accurate shop joker prediction. Unlike the original Immolate DLL approach, this is implemented in pure Lua, making it **fully compatible with macOS**.

To use this filter:
1. Open the game settings
2. Navigate to the "Brainstorm" tab
3. Enable "Search Blueprint/Brainstorm + Money Joker (Antes 1-2)"
4. Press `Ctrl + a` to start auto-rerolling

The mod will automatically search for seeds meeting these criteria and start a run when a matching seed is found.
