# v0.4.4.2:
- (Highscores) frames are now formatted to time
- Attempted to fix more crashes related to the lack of secret inputs
- Fixed secret inputs not being passed through on Big A1, Big A2, and Sakura
- Fixed clearBottomRows function
- T.B.D

# v0.4.4.1:
- Fixed bugs related to 21h

# v0.4.4:
The changes shown here are not in chronological order.
## Major changes:
- Implemented folder support for modes and rulesets
- Implemented the tag system
  - To unselect all tags in menu select, hold Generic 3 input for 1 second
- Implemented mouse support
- Reduced release size down to under 20 MiB
- Reworked the entire input system to allow one key/button to be mapped to multiple inputs
- Added Generic 1-4 inputs
- Target FPS can now be changed by modes, and is shown next to the FPS counter.
  - e.g. on A2 modes, it's `(61.68) 61.68 fps - v0.4.4`
- System inputs are now remappable
- Implemented the resource packs system
- Implemented highscores viewer
- Added new config options: Visual, and Audio
- Moved some game settings to visual settings
- Replays now load asynchronously, and no longer unload when exiting replays menu
- Implemented Tutorial (Key)Binder to interactively map game inputs. (some of it will also map menu inputs here)
- Implemented the save backup system 
  - It'll create a backup if the file successfully loads, otherwise it'll load the backup file
- Updated built-in LOVE version to 11.5.
  - If you were relying on the fact that pairs function was deterministic, redo your code to make sure it works how it should be on Lua, since pairs function does not have any specific order on how it gets values in Lua.
- Added some built-in TAS tools
  - Saving and loading a state is only possible on replays.
  - Framestepping in gameplay (this includes re-recording) is TAS-only, while framestepping on replays does not require TAS mode to be toggled on.
- Implemented file/directory drop handling
  - If it's a directory, it'll ask you if you want to add this as a mod pack
  - If it's a lua file, it'll ask you if it's a mode, or ruleset, or you want to cancel inserting
  - If it's a zip file, it'll ask you if you want to treat this as directory, or add it to resource packs
  - If it's a replay file (.crp), it'll ask you if you want to either view replay data, or insert it into replays folder. To cancel this menu, press X (or red circle on Mac) on the window header.
- New mode selection screen! To see it, go to Settings -> Visual Settings, then select "Mode Select Type", 9th setting there, and set to "Oshi's idea"
- Some menus now have moving lists!
- Implemented the custom ??? sequencing! Start entering them by holding Generic 2 input for 1 second, then input the sequence!

## Other changes:
- Re-added Sakura A3
- The game can now load with some BGMs missing
- Same sound can now have multiple instances of it playing
- Added next piece sound toggle
- Added a visual config for background stretching
- Added total module reload, by holding Generic 1 for 1 second in Game Start menu
- Added cursor highlighting
- 2 new movement types! 4-way LICP and 8-way LICP
  - LICP is Last Input Controlled Priority. First button is inactive unless opposing/last input is released.
- There's more changes that Tetro48 can't be bothered to list out.
