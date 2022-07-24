# Factorio-Utils
A mix of helper libraries and scripts used in many of my mods. Tries to be backwards compatible, but does sometimes have breaking changes made to it.

The `utility` folder is dumped whole in to mods root folder and then built, tested and distributed as part of the mod. This is to make each mod generally self contained that utilise these libraries.

Many of the libraries include using core game events, i.e. on_tick, on_gui_XXX. This means these can't be mixed with other uses of those core game events. No player or entity type events are used.


Root files
-----------
Files in the root are templates I use when starting new mods.


Utility folder
-----------
- colors.lua = A list of standard colors for use across mods.
- commands.lua = Library functions to help manage adding and handling Factorio commands.
- emmylua-classes.lua = 
- events.lua = Library to facilitate multiple functions subscribing to the same script.event in a modular way. Supports custom events and event filters also.
- event-scheduler.lua = Library to facilitate scheduling functions with data to fire on a future tick.
- gui-actions-click.lua = Library to register and handle GUI button clicks, allows registering and handling functions in a modular way.
- gui-actions-closed.lua = Library to register and handle base game GUI types being closed, allows registering and handling functions in a modular way.
- gui-actions-opened.lua = Library to register and handle base game GUI types being opened, allows registering and handling functions in a modular way.
- gui-util.lua = Library to support making, storing and accessing GUI elements.
- logging.lua = Logging functions.
- settings-manager.lua = Library to support using mod settings to acept and array of values for N instances of something. Rather than having to add lots of repeat mod settings entry boxes.
- style-data.lua = Contains the default style prototypes for GUIs I use in mods. WARNING: adds directly to game prototypes and so is not self contained within each mod instance, version mismatch can cause overwriting in rare scenarios.
- utils.lua = Contains all sorts of odd functions, not limited to area entity killing, to evolution specific biter selection to making test prototypes for testing entity placement in/out of water.
- version.txt = The version of the utility folder. Incremented with any impacting changes.
- functions folder - specific functionality libraries:
	- biome-trees.lua = Functions to get tile (biome) approperiate trees. Supports vanilla and Alien Biomes.
	- biter-selection.lua = Functions to get evolution approperiate enemy prototypes.
	- biome-trees-data folder = has internal reference files for the biome-trees functionality.


VSCode Extensions
----------

Copy of VSCode settings file is stored in "VS CODE BITS\vscode extenstions settings". Its location for deployment is: %APPDATA%\Code\User\settings.json
The extensions "vscode-lua" and lua_tags" both add in suggestions that duplicate Lua Code Assist, but are lower quality. Unfortunatly I haven't found any way to still utilise their features and disabling these duplicate entries.

Extensions currently used:
 - Lua (class type definitions): https://marketplace.visualstudio.com/items?itemName=sumneko.lua    documentation: https://github.com/sumneko/lua-language-server/wiki/EmmyLua-Annotations
 - vscode-lua (just for simple formatting and LuaCheck): https://marketplace.visualstudio.com/items?itemName=trixnz.vscode-lua:
	1: Set its Luacheck Path setting to "luacheck". This will find the PATH variable we add later.
 - LuaCheck - I couldn't get LuaCheck to install, so I just used some pre-built files that I knew worked from another extension:
	1: Get the luacheck.exe file from this overly comphrensive extension (I used to use it): https://github.com/changnet/lua-tags/tree/master/luacheck
	2: Create a new folder called LuaCheck on the PC (i.e. C:\Program Files\LuaCheck) and put the file in it.
	3: Grant all users modify permission to the folder.
	4: Add the folder to the system's (not user's) Path variable.
 - Factorio Lua Check RC files: https://github.com/Nexela/Factorio-luacheckrc
	1: Download the .luacheckrc file and defines-parser.lua file and put in the root of the Factorio Modding folder (or in the root of each mod's folder).
	2: Make the changes post file download as defined in "Factorio Lua Check RC Changes".
 - Factorio Mod Debug: https://marketplace.visualstudio.com/items?itemName=justarandomgeek.factoriomod-debug
	- Utils copy of config files at "VS CODE BITS\Per Mod .vscode", put its contents in the mods specific folder in a ".vscode" folder
 - Setup Factorio lua code assist and autocomplete global settings: https://github.com/justarandomgeek/vscode-factoriomod-debug/blob/master/workspace.md
	- To generate EmmyLua docs for the Factorio API from the JSON docs press use the Factorio version selector on the status bar (bottom of VSCode) and browse to the exe. Select it and manually enter its Factorio version. This will create the docs in the root of the Factorio folder in a new folder (based on our global extension settings).
 - indent-rainbow: https://marketplace.visualstudio.com/items?itemName=oderwat.indent-rainbow
 - GitLens: https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens
 - compareit: https://marketplace.visualstudio.com/items?itemName=in4margaret.compareit
 - FactorioSumnekoLuaPlugin (helps autocomplete with Factorio specific oddities):
	1: Download the git repo from: https://github.com/JanSharp/FactorioSumnekoLuaPlugin
	2: Get the contents of the downloaded Zip/folder. Where the README.md is.
	3: In the root of the shared Factorio modding source folder, the folder each of your mods source code folders live in.
	4: Create a new folder structure: ".vscode" / "lua"
	5: Put the downloaded contents inside the lua folder created. So you end up with: [MY FACTORIO MODS]/.vscode/lua/README.md
	6: In VSCode set the "sumneko.lua" extensions "Plugin" setting to the shared source folder root and path you creaed: ../.vscode/lua/plugin.lua