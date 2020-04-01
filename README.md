# Factorio-Utils
A mix of helper libraries and scripts used in many of my mods. Tries to be backwards compatible, but does sometimes have breaking changes made to it.

The `utility` folder is dumped whole in to mods root folder and then built, tested and distributed as part of the mod. This is to make each mod generally self contained that utilise these libraries.


Root files
-----------
Files in the root are templates I use when starting new mods.


Utility folder
-----------
- colors.lua = A list of standard colors for use across mods.
- commands.lua = Library functions to help manage adding and handling Facotrio mod commands.
- event-scheduler.lua = Library to facilitate scheduling functions with data to fire on a future tick.
- events.lua = Library to facilitate multiple functions subscribing to the same event in a modular way. Supprts custom events and event filters also.
- gui-actions.lua = Library to register and handle GUI actions (button clicks) registering and handling functions in a modular way.
- gui-util.lua = Library to support making, storing and accessing GUI elements.
- interfaces.lua = Library to allow registering functions as interfaces internally within the mod to support modualr mod design.
- logging.lua = Logging functions.
- settings-manager.lua = Library to support using mod settings to acept and array of values for N instances of something. Rather than having to add lots of repeat mod settings entry boxes.
- style-data.lua = Contains the default style prototypes for GUIs I use in mods. WARNING: adds directly to game prototypes and so is not self contained within each mod instance, version mismatch can cause overwriting in rare scenarios.
- utils.lua = Contains all sorts of odd functions, not limited to area entity killing, to evolution specific biter selection to making test prototypes for testing entity placement in/out of water.
- version.txt = The version of the utility folder. Incremented with any impacting changes.


VSCode Extensions
----------

The VSCode settings file is stored in this folder. Its location for deployment can be found here:
https://code.visualstudio.com/docs/getstarted/settings#_settings-file-locations

Extensions currently used:
 - Lua Coder Assist: https://marketplace.visualstudio.com/items?itemName=liwangqian.luacoderassist
 - Lua Plus: https://marketplace.visualstudio.com/items?itemName=jep-a.lua-plus
 - Factorio Lua API autocomplete (rather out of date): https://marketplace.visualstudio.com/items?itemName=svizzini.factorio-lua-api-autocomplete
 - Factorio Lua Check RC: https://github.com/Nexela/Factorio-luacheckrc
 - Factorio Mod Debug: https://marketplace.visualstudio.com/items?itemName=justarandomgeek.factoriomod-debug