--[[
    Event related utility functions. Separate to the Events library for registering event handlers.
]]
--

local EventUtils = {} ---@class Utility_EventUtils

EventUtils.WasCreativeModeInstantDeconstructionUsed = function(event)
    if event.instant_deconstruction ~= nil and event.instant_deconstruction == true then
        return true
    else
        return false
    end
end

---@alias EntityActioner LuaPlayer|LuaEntity # The placer of a built entity, either player or construction robot. A script will have a nil value.

--- Get the thing that did the building/mining from an event.
---@param event EventData.on_built_entity|EventData.on_robot_built_entity|EventData.script_raised_built|EventData.script_raised_revive|EventData.on_pre_player_mined_item|EventData.on_robot_pre_mined
---@return EntityActioner? placer # Player, construction robot or nil if script done.
EventUtils.GetActionerFromEvent = function(event)
    if event.robot ~= nil then
        -- Construction robots
        return event.robot
    elseif event.player_index ~= nil then
        -- Player
        return game.get_player(event.player_index)
    else
        -- Script placed
        return nil
    end
end

--- Returns either the player or force for robots from the EntityActioner.
---
--- Useful for passing in to rendering player/force filters or for returning items to them.
---@param actioner EntityActioner
---@return LuaPlayer?
---@return LuaForce?
EventUtils.GetPlayerOrForceFromEventActioner = function(actioner)
    if actioner.is_player() then
        -- Is a player.
        return actioner--[[@as LuaPlayer]] , nil
    else
        -- Is construction bot.
        return nil, actioner.force --[[@as LuaForce]]
    end
end

return EventUtils
