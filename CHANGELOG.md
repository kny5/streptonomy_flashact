# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to
[Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add option to pick a specific control type in the control settings.
- Add fade transition when opening and exiting the game.

### Changed

- Allow binding the joysticks in the control settings.
- Make nanogame inputs use the left joystick by default when using a joypad.
- Hide pause button when using a joypad.
- Keep popup dialogs centered when the screen size is changed.

### Fixed

- Fix nanogame physics sometimes breaking on higher speeds.
- Nanogames:
  - Woozy Chomper: Fix Woozy's body segments still moving once the nanogame is
  over.
- Fix rare, yet insistent bug in the nanogame selection screen when typing too
fast, again...
- Fix best scores not being updated if a new one has the same points as the
others.

## [0.5.0] - 2021-11-20

### Added

- Add joypad support for nanogames with the input type "Screen" (now called
"Drag and Drop"), making the game fully playable through a controller!
- Add nanogames:
  - Digital Warp
  - Garden Thyme
  - Gravity Shift
  - Hop for Love
- Add current nanogame summary to the pause screen.
- Add some eye candy to the arcade menu.

### Changed

- Rename the "Screen" input type for nanogames to "Drag and Drop".
- Keep pause button visible during nanogame intermissions.
- Nanogames:
  - Countin' Candy: Slightly decrease max possible quantity of candy.
  - Gadget Inspection: Tone down target area size decrease on later difficulty
  levels.
  - Punchbag Wallop: Make difficulty 1 punching bag swing away after 3 hits and
  decrease punches needed from 12 to 9, to better exemplify how later
  difficulty levels work. Also increase hits needed from 5 to 6 for the
  difficulty 3 bag.
  - Thing Factory: Change some visuals to better indicate the objective.
- Allow wrapping around when switching tabs with the joypad triggers.

### Fixed

- Fix weird resolution in nanogames while in windowed mode if the window size
is never changed.
- Fix crash when using the joypad triggers while changing the controls in the
settings dialog.
- Fix nanogame buttons in the selection screen not being reorganized on
language change.

## [0.4.1] - 2021-04-26

### Changed

- Nanogames:
  - Punchbag Wallop: Reduce length of the "punch missed" animation.

### Fixed

- Fix "Randomize" button picking official nanogames on community mode in the
selection screen.

## [0.4.0] - 2021-04-21

### Added

- Add music! A menu theme and various jingles all composed by Francesco
Corrado.
- Add control settings. With options to change nanogame controls, and to mirror
the positions of touch buttons.
- Add nanogames:
  - Buzzing Lunch
  - Countin' Candy
  - Shuffle Dance
  - Suitcase-by-Case
  - Woozy Chomper
- Add labels showing how much was gained on score and tickets counters.
- Add "Contributors" tab to the "About" dialog.
- Add new phrases to the nanogame intermissions.

### Changed

- Unify the nanogame selection and random screens.
- Improve the directional touch controls. Now allowing diagonal inputs.
- Nanogames:
  - Anagogic Clock: Add a "x" mark to empty slots in the time display, to
  better convey that any number is acceptable for them.
  - Ballkeep: Slow down the ball at the start, but raise the speed further
  after the first bounce. Also add arrows on the dominant paddle that disappear
  after moving it.
  - Punchbag Wallop: Make punching bags translucent when they flinch away and
  can't be hit.
  - Thing Factory: Make "things" spawn indefinitely instead of a fixed amount.
  Also increase size of their touch area.
  - Void Avoider: Increase minimum distance between the player and black hole
  spawns.
- Allow choosing which difficulty to start from in practice mode.
- It's now possible to pause/quit at the very start of nanogame playing.
- Double best score slots in the statistics screen from 3 to 6.
- Allow for search terms in the selection screen to only contain negatives.
- Disable "Mute When the Game Loses Focus" option by default, as it doesn't
work correctly on some cases.
- Make status icons on the pause menu in the nanogame HUD have the same color
as their unpaused counterparts.
- Various minor visual changes across the game's interface.

### Fixed

- Fix occasions where one could start playing with less nanogames selected than
necessary in the selection screen.
- Fix bug in nanogame selection screen when typing too fast in the search bar.
Turns out that it wasn't Android only.
- Nanogames:
  - Papercuts: Fix cutting very close to the inner cutout area making the
  nanogame unwinnable instead of triggering the failure state in rare
  occasions.
  - Void Avoider: Fix black hole spawns being wrongfully offset, leading to
  some cases where it could spawn inside the player.
- Fix ellipsis on cutoff names in nanogame buttons glitching on window resize.
- Fix "Start" button's tooltip in the arcade menu appearing even when hidden.

## [0.3.0] - 2020-08-15

### Added

- Add nanogames:
  - Gadget Inspection
  - Gem Enchantment
  - Papercuts
- Add visual reference to the number of nanogames needed to be selected to
start playing.
- Show tooltips to cutoff labels on nanogame buttons in the selection screen.
- Make possible to access the "community_nanogames" directory via the
choose/random screens.

### Changed

- Heavily improve the joypad experience when navigating the interface. With a
visual indicator of the current UI element focused, better navigation from one
element to another, and the possibility to change tabs which the shoulder
buttons.
- Nanogames:
  - Anagogic Clock: Change the ambiance sound effect to piano music.
  - Ballkeep: Make paddle rotation be from the top one's perspective, and the
  bottom paddle be the one to disappear in difficulty 3.
  - Rope Hop: Slightly increase jump distance of enemies.
- Reposition the "Randomize" button and enable its text clearing functionality
in the random selection screen.
- Make touch buttons in nanogame HUD update immediately on joypad
(dis)connection and toggle of showing them by force.
- Make language names be shown in their respective languages in the settings
dialog.

### Fixed

- Fix volume sliders looking unthemed when focused.
- Nanogames:
  - Anagogic Clock: Fix hands listening to any input other than the left mouse
  button on the desktop.
- Fix difficulty up message appearing on nanogame transition while it's already
maxed.
- Fix contents of the random selection screen overflowing on the minimal window
width.

## [0.2.0] - 2020-06-26

### Added

- Add nanogames:
  - Ballkeep
  - Rope Hop
  - Thing Factory
- Add practice mode. Sharpen your skills on a specific nanogame without
worrying about energy points.
- Add German translation (thanks to Wuzzy).

### Changed

- Revamp touch buttons. Adding pass-through functionality, and lightly changed
appearance.
- Nanogames:
  - Anagogic Clock: Allow for an margin error of 1 minute on the last
  difficulty.
  - Input Flow: Remove number system, and make difficulty 2 have 5 inputs.
  - Punchbag Wallop: At difficulty 3, make the bag need 5 punches instead of 4
  to be destroyed.
  - Void Avoider: Make the no-spawn area of black holes slightly bigger.
- Remove vertical borders in the arcade interface. Giving it a more clear look.
- Apply small cosmetic change to vertical scrollbar.

### Fixed

- Fix previously played nanogames never actually being cleared.
- Fix crash for nanogames that fire the 'ended' signal when something vanishes.
- Fix nanogame filtering not taking into account other languages.
- Fix audio speed not quite matching the game speed.
- Fix menu noise being played when pressing the shortcut while no sub-menus are
open.
- Fix item on "Inputs" list in the random selection screen being cutoff.
- Fix difficulty and speed icon bugs related to their colors.
- Fix text alignment in "Community Nanogames" toggle when changing from certain
languages.

## [0.1.1] - 2020-04-24

### Fixed

- Fix bug in nanogame selection screen when typing too fast in the filter bar.
This error is very easy to encounter on Android.
- Fix error when changing the language while playing a nanogame.
- Fix some areas not updating their texts when changing the language.
- Fix incorrect source link in "Anagogic Clock" nanogame.

[Unreleased]: https://codeberg.org/Librerama/librerama/compare/v0.5.0...master
[0.5.0]: https://codeberg.org/Librerama/librerama/compare/v0.4.1...v0.5.0
[0.4.1]: https://codeberg.org/Librerama/librerama/compare/v0.4.0...v0.4.1
[0.4.0]: https://codeberg.org/Librerama/librerama/compare/v0.3.0...v0.4.0
[0.3.0]: https://codeberg.org/Librerama/librerama/compare/v0.2.0...v0.3.0
[0.2.0]: https://codeberg.org/Librerama/librerama/compare/v0.1.1...v0.2.0
[0.1.1]: https://codeberg.org/Librerama/librerama/compare/v0.1.0...v0.1.1
