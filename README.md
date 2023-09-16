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

Extensions currently used:
 - Lua (class type definitions): https://marketplace.visualstudio.com/items?itemName=sumneko.lua    documentation: https://github.com/sumneko/lua-language-server/wiki/EmmyLua-Annotations
	- Does TypeDef checks based on user settings and a few workspace settings placed by Factorio Mod Debug.
	- Does Formatting as default from formatter (no .editorconfig), with any required settings done via user settings.
 - Factorio Mod Debug: https://marketplace.visualstudio.com/items?itemName=justarandomgeek.factoriomod-debug
	- Utils copy of config files at "VS CODE BITS\Per Mod .vscode", put its contents in the mods specific folder in a ".vscode" folder
	- To generate EmmyLua docs for the Factorio API from the JSON docs press use the Factorio version selector on the status bar (bottom of VSCode) and browse to the exe. This will create the docs in the root of the Factorio folder in a new folder (based on our global extension settings).
 - indent-rainbow: https://marketplace.visualstudio.com/items?itemName=oderwat.indent-rainbow
 - GitLens: https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens
 - compareit: https://marketplace.visualstudio.com/items?itemName=in4margaret.compareit
 - Code Spell Checker: https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker
	1: most settings are in the user's VS code settings. This includes the path to where it expects the custom dictionaries to be.
	2: In the root of the shared Factorio modding source folder (same as FactorioSumnekoLuaPlugin), have a ".vscode" folder.
	3: Within here create another folder called "cspell" and put the "cSpell Dictionaries" contents from Utils repo in there.
	
Extra things added to VSCode:
 - Factorio API (data stage typedefs): https://github.com/Nexela/factorio-api
	1: Download the repo and put the files in a created folder: C:\FactorioModding\factorio-api
	2: Add the folder to Sumneko (per workspace not per user) library paths: setting name "Library", path to add: C:\FactorioModding\factorio-api