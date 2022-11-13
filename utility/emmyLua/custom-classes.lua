--[[
    Generic EmmyLua classes. You don't need to require this file anywhere, EmmyLua will discover it within the workspace.
--]]
--
---@meta
---@diagnostic disable

--- The entities unit_number or "destroyedId_[UNIQUE_NUMBER_PER_ENTITY]". Created with code like `entity.unit_number or ("destroyedId_" .. script.register_on_entity_destroyed(entity))`.
---@alias EntityIdentifier string|uint

--- A base class for EventFilter specific class types. Useful for doing generic handling logic prior to a specific EventFilter being typed. The common fields from EventFilter.
---
---**Note:** Filters are always used as an array of filters of a specific type. Every filter can only be used with its corresponding event, and different types of event filters can not be mixed.
---
---[View documentation](https://lua-api.factorio.com/latest/Concepts.html#EventFilter)
---@class EventFilter_Base
---@field filter string
---@field mode? "or"|"and" # Defaults to `or` if not provided.
---@field invert? boolean # Defaults to `false`.




--[[

Example of defining a dictionary as containing all the same type of values en-bulk.
With just this you can't valid the dictionary level, just the selected value in it.

---@type {[string]:Color}
local Colors = {}




Often a Factorio returned type will differ from expected due to it having different types for its read and write. There are ongoing works to fix this, but for now just "@as" to fix it with a comment that its a work around and not an intentional "@as".
NOTE: in the below example the * from the end of each line needs to be removed so the comment closes. Its just in this example reference the whole block is already in a comment and so we can't let it close on each line.

local player = game.players[1] -- Is type of LuaPlayer.
local force ---@type LuaForce
force = player.force --[[@as LuaForce # Debugger Sumneko temp fix for different read/write]*]

--]]
--
