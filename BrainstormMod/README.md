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

#### Custom Filters

All custom filters use exact RNG seed strings reverse-engineered from Balatro's code (based on the [Brainstorm-Rerolled](https://github.com/ABGamma/Brainstorm-Rerolled) Immolate C++ implementation), ensuring accurate prediction. Unlike the original Immolate DLL approach, this is implemented in pure Lua, making it **fully compatible with macOS**.

**Blueprint/Brainstorm Filter**
- Searches for seeds where **Blueprint** OR **Brainstorm** joker appears in the **initial shop** (first 2 slots, no rerolls) during **Ante 1 or Ante 2**
- Enable toggle: "Search Blueprint/Brainstorm (Antes 1-2)"
- Logs to console when found

**Money Joker Filter**
- Searches for seeds where a money-generating joker appears in the **initial shop** (first 2 slots, no rerolls) during **Ante 1 or Ante 2**
- Money jokers: Mail-in Rebate, Business Card, Cloud 9, Rocket, Midas Mask, Gift Card, Reserved Parking, Golden Joker, Trading Card
- Enable toggle: "Search Money Joker (Antes 1-2)"
- Logs to console when found

**Negative Blueprint/Brainstorm Filter**
- Searches for seeds where **Negative edition Blueprint** OR **Brainstorm** joker appears in the **initial shop** during **Ante 1 or Ante 2**
- Negative edition gives +1 joker slot
- Enable toggle: "Search Negative Blueprint/Brainstorm (Antes 1-2)"
- Logs to console when found

**God King Filter**
- Searches for seeds where the first booster pack is a Standard Pack containing a very specific card:
  - **Any face card** (King, Queen, or Jack - no Aces)
  - **Any suit** (Spades, Hearts, Diamonds, or Clubs)
  - **Gold OR Steel enhancement** (Gold multiplies card value, Steel gives +50 chips)
  - **Polychrome edition** (+mult and Xmult bonuses)
  - **Red seal** (retrigger card effect)
- This combination is extremely rare and powerful for early game scoring
- Enable toggle: "Search Polychrome Gold/Steel Red-Seal Face Card (First Pack)"
- Logs to console when found

**Using Multiple Filters Simultaneously**

All custom filters can be used **together** - the mod will only find seeds that match **ALL enabled filters**. For example:
- Enable both "Blueprint/Brainstorm" and "Money Joker" to find seeds with both joker types
- Enable all three filters to find seeds with Blueprint/Brainstorm, Money Joker, AND the god king card
- Filters are logged to console when they match, helping you understand which criteria are being met

**How to Use:**
1. Open the game settings
2. Navigate to the "Brainstorm" tab
3. Enable any combination of filters
4. Press `Ctrl + a` to start auto-rerolling
5. Check your console output to see filter matches in real-time (prints like "[Brainstorm] Found Blueprint/Brainstorm in seed: ABCD1234")
