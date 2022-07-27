# Factorio-Utils
A mix of helper libraries and scripts used in many of my mods. Tries to be backwards compatible, but does sometimes have breaking changes made to it, flagged by minor (middle) version number changes.
The major version relates to which Factorio version its for. 18 is for Factorio v0.18, 19 for v1.0, 20 for v1.1.

The `utility` folder is dumped whole in to mods root folder and then built, tested and distributed as part of the mod. This is to make each mod generally self contained that utilise these libraries.

Many of the libraries include using core game events, i.e. on_tick, on_gui_XXX. This means these can't be mixed with other uses of those core game events. No player or entity type events are used.


Mod Template Files
-----------
The files I use as templates when starting new mods.


Utility folder
-----------
A bunch of managers, related utility functions and lists of common things. Put this folder directly in the root of the mod's workspace.


VSCode Extensions
----------

Copy of VSCode settings file is stored in "VS CODE BITS\vscode extenstions settings". It's location for deployment is: %APPDATA%\Code\User\settings.json
The extensions "vscode-lua" and lua_tags" both add in suggestions that duplicate Lua Code Assist, but are lower quality. Unfortunatly I haven't found any way to still utilise their features and disabling these duplicate entries.

Extensions currently used:
 - Lua (class type definitions): https://marketplace.visualstudio.com/items?itemName=sumneko.lua    documentation: https://github.com/sumneko/lua-language-server/wiki/EmmyLua-Annotations
 - vscode-lua (just for simple formatting and LuaCheck): https://marketplace.visualstudio.com/items?itemName=trixnz.vscode-lua:
	1: Set its Luacheck Path setting to "luacheck". This will find the PATH variable we add later.
	2 LuaCheck - I couldn't get LuaCheck to install, so I just used some pre-built files that I knew worked from another extension:
		1: Get the luacheck.exe file from this overly comphrensive extension (I used to use it): https://github.com/changnet/lua-tags/tree/master/luacheck
		2: Create a new folder called LuaCheck on the PC (i.e. C:\Program Files\LuaCheck) and put the file in it.
		3: Grant all users modify permission to the folder.
		4: Add the folder to the system's (not user's) Path variable.
 - Factorio Lua Check RC files: https://github.com/Nexela/Factorio-luacheckrc
	1: Download the .luacheckrc file and defines-parser.lua file and put in the root of the Factorio Modding folder (or in the root of each mod's folder).
	2: Make the changes post file download as defined in "Factorio Lua Check RC Changes".
 - Factorio Mod Debug: https://marketplace.visualstudio.com/items?itemName=justarandomgeek.factoriomod-debug
	- Utils copy of config files at "VS CODE BITS\Per Mod .vscode", put its contents in the mods specific folder in a ".vscode" folder
 - Setup Factorio lua code assist and autocomplete global settings.
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
 - Code Spell Checker: https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker
	1: most settings are in the user's VS code settings. This includes the path to where it expects the custom dictionaries to be.
	2: In the root of the shared Factorio modding source folder (same as FactorioSumnekoLuaPlugin), have a ".vscode" folder.
	3: Within here create another folder called "cspell" and put the "cSpell Dictionaries" contents from Utils repo in there.