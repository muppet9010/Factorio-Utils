--[[
    This event scheduler is used by calling the RegisterScheduler() function once in root of control.lua. You then call RegisterScheduledEventType() from the OnLoad stage for each function you want to register for future triggering. The triggering is then done by using the Once or Each Tick functions to add and remove registrations of functions and data against Factorio events. Each Tick events are optional for use when the function will be called for multiple ticks in a row with the same reference data.
--]]

-- Make Automatic Testing: make tests for this at end of file. Either have runnable via command and commented out or for pasting the whole file in to Demo Lua. Should check that the results all come back as expected for the various schedule add/remove/get/etc functions as I'd like to simplify the _ParseScheduledEachTickEvents() actionFunction response objects and their handling as was hard to document and messy.

--[[
    CODE NOTES:
    - For ease of updating code the code in the Every Tick functions is basically the same as the Per Tick functions. This is overkill in places for the Every Tick, but they are rarely called and so the wasted few Lua code lines is irrelevant.
]]

local Events = require("utility.manager-libraries.events")
local EventScheduler = {} ---@class Utility_EventScheduler
MOD = MOD or {} ---@class MOD
---@type table<string, function>
MOD.scheduledEventNames =
MOD.scheduledEventNames or
    {
        ["EventScheduler.GamePrint"] = function(event)
            -- Builtin game.print delayed function, needed for 0 tick logging (startup) writing to screen activities.
            game.print(event.data.message)
        end
    }

---@class UtilityScheduledEvent_CallbackObject
---@field tick uint # The current game tick.
---@field name string # The name of the scheduled event, as registered with EventScheduler.RegisterScheduledEventType().
---@field instanceId string|number # The instanceId the event was scheduled with.
---@field data table # The custom data table that was provided when the event was scheduled or an empty table if none was provided.

---@class UtilityScheduledEvent_Information # Information about a scheduled event returned by some public query functions.
---@field tick? uint # nil for events scheduled every tick, but populated for events scheduled for specific ticks.
---@field eventName string
---@field instanceId string|number
---@field eventData table

---@alias UtilityScheduledEvent_EventData table<any, any> # The event data that will be provided when the event triggers.

---@alias UtilityScheduledEvent_UintNegative1 uint|"-1" # Accepted when scheduling an event.

--------------------------------------------------------------------------------------------
--                                    Setup Functions
--------------------------------------------------------------------------------------------

--- Register the scheduler as it requires exclusive access to the on_tick Factorio event.
---
--- Called from the root of Control.lua
---
--- Only needs to be called once by the mod.
EventScheduler.RegisterScheduler = function()
    Events.RegisterHandlerEvent(defines.events.on_tick, "EventScheduler._OnSchedulerCycle", EventScheduler._OnSchedulerCycle)
end

--- Used to register an event name to an event function. The event name is scheduled separately as desired.
---
--- Called from OnLoad() from each script file.
---@param eventName string
---@param eventFunctionCallback function # The callback function that is called when the scheduled event triggers. The callback function receives a single parameter of type UtilityScheduledEventCallbackObject with relevant information, including any custom data (eventData) populated during the scheduling.
EventScheduler.RegisterScheduledEventType = function(eventName, eventFunctionCallback)
    if eventName == nil or eventFunctionCallback == nil then
        error("EventScheduler.RegisterScheduledEventType called with missing arguments")
    end
    MOD.scheduledEventNames[eventName] = eventFunctionCallback
end

--------------------------------------------------------------------------------------------
--                                    Schedule Once Functions
--------------------------------------------------------------------------------------------

--- Schedules an event name to run once at a set tick.
---
--- Called from OnStartup() or from some other event or trigger to schedule an event.
---
--- When the event fires the registered function receives a single UtilityScheduledEvent_CallbackObject argument.
---@param eventTick? UtilityScheduledEvent_UintNegative1 # A value of nil will be next tick, current or past ticks will fail. a value of -1 is a special input for current tick when used by events that run before the Factorio on_tick event, i.e. a custom input (key pressed for action) handler.
---@param eventName string # The event name used to lookup the function to call, as registered with EventScheduler.RegisterScheduledEventType().
---@param instanceId string|number # A unique Id to identify this scheduled event and its data for this eventName on the given tick.
---@param eventData? UtilityScheduledEvent_EventData # Custom table of data that will be returned to the triggered function when called as the "data" attribute of the UtilityScheduledEventCallbackObject object.
---@param currentTick uint # The current game tick.
EventScheduler.ScheduleEventOnce = function(eventTick, eventName, instanceId, eventData, currentTick)
    if eventName == nil or instanceId == nil then
        error("EventScheduler.ScheduleEventOnce called with missing arguments")
    end
    if eventTick == nil then
        eventTick = currentTick + 1
    elseif eventTick == -1 then
        -- Special case for callbacks within same tick.
        eventTick = currentTick
    elseif eventTick <= currentTick then
        error("EventScheduler.ScheduleEventOnce scheduled for in the past. eventName: '" .. tostring(eventName) .. "' instanceId: '" .. tostring(instanceId) .. "'")
    end ---@cast eventTick uint
    eventData = eventData or {}
    global.UTILITYSCHEDULEDFUNCTIONS = global.UTILITYSCHEDULEDFUNCTIONS or {} ---@type UtilityScheduledEvent_ScheduledFunctionsTicks
    local tickEvents = global.UTILITYSCHEDULEDFUNCTIONS[eventTick]
    if tickEvents == nil then
        tickEvents = {}
        global.UTILITYSCHEDULEDFUNCTIONS[eventTick] = tickEvents
    end
    local tickNamedEvent = tickEvents[eventName]
    if tickNamedEvent == nil then
        tickNamedEvent = {}
        tickEvents[eventName] = tickNamedEvent
    end
    if tickNamedEvent[instanceId] ~= nil then
        error("EventScheduler.ScheduleEventOnce tried to override schedule event: '" .. eventName .. "' id: '" .. instanceId .. "' at tick: " .. eventTick)
    else
        tickNamedEvent[instanceId] = eventData
    end
end

--- Checks if an event name is scheduled as per other arguments.
---
--- Called whenever required.
---@param targetEventName string # The event name as registered with EventScheduler.RegisterScheduledEventType().
---@param targetInstanceId string|number # The instance Id of the scheduled event to check for.
---@param targetTick? uint # The tick to check for the scheduled event in. If not provided checks all scheduled event ticks.
---@return boolean
EventScheduler.IsEventScheduledOnce = function(targetEventName, targetInstanceId, targetTick)
    if targetEventName == nil or targetInstanceId == nil then
        error("EventScheduler.IsEventScheduledOnce called with missing arguments")
    end
    local result = EventScheduler._ParseScheduledOnceEvents(targetEventName, targetInstanceId, targetTick, EventScheduler._IsEventScheduledOnceInTickEntry)
    if result ~= true then
        result = false
    end
    return result
end

--- Removes the specified scheduled event that matches all supplied filter arguments.
---
--- Called whenever required.
---@param targetEventName string # The event name to removed as registered with EventScheduler.RegisterScheduledEventType().
---@param targetInstanceId string|number # The instance Id of the scheduled event to match against.
---@param targetTick? uint # The tick the scheduled event must be for. If not provided matches all ticks.
---@return uint removedEventCount # How many instances of scheduled events were removed.
EventScheduler.RemoveScheduledOnceEvents = function(targetEventName, targetInstanceId, targetTick)
    if targetEventName == nil or targetInstanceId == nil then
        error("EventScheduler.RemoveScheduledOnceEvents called with missing arguments")
    end
    -- We can't count the entries within the _ParseScheduledOnceEvents(), but can have each execution of _RemoveScheduledOnceEventsFromTickEntry() return the number of scheduled entries it removed.
    local _, results = EventScheduler._ParseScheduledOnceEvents(targetEventName, targetInstanceId, targetTick, EventScheduler._RemoveScheduledOnceEventsFromTickEntry)
    if next(results) ~= nil then
        -- Some scheduled events were removed so check how many.
        local removedEventCount = 0 ---@type uint
        for _, countInTick in pairs(results) do
            removedEventCount = removedEventCount + countInTick
        end
        return removedEventCount
    else
        -- Nothing was removed.
        return 0
    end
end

--- Returns an array of the scheduled events that match the filter arguments.
---
--- Called whenever required.
---@param targetEventName string # The event name as registered with EventScheduler.RegisterScheduledEventType().
---@param targetInstanceId string|number # The instance Id of the scheduled event to match against.
---@param targetTick? uint # The tick the scheduled event must be for. If not provided matches all ticks.
---@return UtilityScheduledEvent_Information[] results
EventScheduler.GetScheduledOnceEvents = function(targetEventName, targetInstanceId, targetTick)
    if targetEventName == nil or targetInstanceId == nil then
        error("EventScheduler.GetScheduledOnceEvents called with missing arguments")
    end
    local _, results = EventScheduler._ParseScheduledOnceEvents(targetEventName, targetInstanceId, targetTick, EventScheduler._GetScheduledOnceEventsFromTickEntry)
    return results
end

--------------------------------------------------------------------------------------------
--                                    Schedule For Each Tick Functions
--------------------------------------------------------------------------------------------

--- Schedules an event name to run each tick.
---
--- Called from OnStartup() or from some other event or trigger to schedule an event to fire every tick from now on until cancelled.
---
--- Good if you need to pass data back with each firing and the event is going to be stopped/started. If its going to run constantly then better to just register for the on_tick event handler via the Events utility class.
---
--- When the event fires the registered function receives a single UtilityScheduledEvent_CallbackObject argument.
---@param eventName string # The event name used to lookup the function to call, as registered with EventScheduler.RegisterScheduledEventType().
---@param instanceId string|number # A unique Id to identify this scheduled event and its data for this eventName.
---@param eventData? UtilityScheduledEvent_EventData # Custom table of data that will be returned to the triggered function when called as the "data" attribute.
EventScheduler.ScheduleEventEachTick = function(eventName, instanceId, eventData)
    if eventName == nil or instanceId == nil then
        error("EventScheduler.ScheduleEventEachTick called with missing arguments")
    end
    eventData = eventData or {}
    global.UTILITYSCHEDULEDFUNCTIONSPERTICK = global.UTILITYSCHEDULEDFUNCTIONSPERTICK or {} ---@type UtilityScheduledEvent_ScheduledFunctionsPerTickEventNames
    local namedEventInstances = global.UTILITYSCHEDULEDFUNCTIONSPERTICK[eventName]
    if namedEventInstances == nil then
        namedEventInstances = {} ---@type UtilityScheduledEvent_ScheduledFunctionsPerTickEventNamesInstanceIds
        global.UTILITYSCHEDULEDFUNCTIONSPERTICK[eventName] = namedEventInstances
    end
    if namedEventInstances[instanceId] ~= nil then
        error("WARNING: Overridden schedule event per tick: '" .. eventName .. "' id: '" .. instanceId .. "'")
    else
        namedEventInstances[instanceId] = eventData
    end
end

--- Checks if an event name is scheduled each tick as per other arguments.
---
--- Called whenever required.
---@param targetEventName string # The event name to removed as registered with EventScheduler.RegisterScheduledEventType().
---@param targetInstanceId string|number # The instance Id of the scheduled event to match against.
---@return boolean
EventScheduler.IsEventScheduledEachTick = function(targetEventName, targetInstanceId)
    if targetEventName == nil then
        error("EventScheduler.IsEventScheduledEachTick called with missing arguments")
    end
    local result = EventScheduler._ParseScheduledEachTickEvents(targetEventName, targetInstanceId, EventScheduler._IsEventScheduledInEachTickList)
    if result ~= true then
        result = false
    end
    return result
end

--- Removes the specified scheduled event each tick that matches all supplied filter arguments.
---
--- Called whenever required.
---@param targetEventName string # The event name to removed as registered with EventScheduler.RegisterScheduledEventType().
---@param targetInstanceId string|number # The instance Id of the scheduled event to match against.
---@return boolean removedEvent
EventScheduler.RemoveScheduledEventFromEachTick = function(targetEventName, targetInstanceId)
    if targetEventName == nil then
        error("EventScheduler.RemoveScheduledEventsFromEachTick called with missing arguments")
    end
    local _, results = EventScheduler._ParseScheduledEachTickEvents(targetEventName, targetInstanceId, EventScheduler._RemoveScheduledEventFromEachTickList)
    if next(results) ~= nil then
        -- A scheduled events were removed.
        return true
    else
        -- Nothing was removed.
        return false
    end
end

--- Returns the scheduled event each tick that match the filter arguments.
---
--- Called whenever required.
---@param targetEventName string # The event name as registered with EventScheduler.RegisterScheduledEventType().
---@param targetInstanceId string|number # The instance Id of the scheduled event to match against.
---@return UtilityScheduledEvent_Information[]? results
EventScheduler.GetScheduledEachTickEvent = function(targetEventName, targetInstanceId)
    if targetEventName == nil then
        error("EventScheduler.GetScheduledEachTickEvent called with missing arguments")
    end
    local _, results = EventScheduler._ParseScheduledEachTickEvents(targetEventName, targetInstanceId, EventScheduler._GetScheduledEventFromEachTickList)
    return results
end

--------------------------------------------------------------------------------------------
--                                    Internal Functions
--------------------------------------------------------------------------------------------

--- Runs every tick and actions both any scheduled events for that tick and any events that run every tick. Removes the processed scheduled events as it goes.
---@param event EventData.on_tick
EventScheduler._OnSchedulerCycle = function(event)
    local tick = event.tick
    if global.UTILITYSCHEDULEDFUNCTIONS ~= nil and global.UTILITYSCHEDULEDFUNCTIONS[tick] ~= nil then
        for eventName, instances in pairs(global.UTILITYSCHEDULEDFUNCTIONS[tick]) do
            for instanceId, scheduledFunctionData in pairs(instances) do
                local eventData = { tick = tick, name = eventName, instanceId = instanceId, data = scheduledFunctionData }
                if MOD.scheduledEventNames[eventName] ~= nil then
                    MOD.scheduledEventNames[eventName](eventData)
                else
                    error("WARNING: schedule event called that doesn't exist: '" .. eventName .. "' id: '" .. instanceId .. "' at tick: " .. tick)
                end
            end
        end
        global.UTILITYSCHEDULEDFUNCTIONS[tick] = nil
    end
    if global.UTILITYSCHEDULEDFUNCTIONSPERTICK ~= nil then
        -- Prefetch the next table entry as we will likely remove the inner instance entry and its parent eventName while in the loop. Advised solution by Factorio discord.
        local eventName, instances = next(global.UTILITYSCHEDULEDFUNCTIONSPERTICK)
        while eventName do
            local nextEventName, nextInstances = next(global.UTILITYSCHEDULEDFUNCTIONSPERTICK, eventName)
            for instanceId, scheduledFunctionData in pairs(instances) do
                ---@type UtilityScheduledEvent_CallbackObject
                local eventData = { tick = tick, name = eventName, instanceId = instanceId, data = scheduledFunctionData }
                if MOD.scheduledEventNames[eventName] ~= nil then
                    MOD.scheduledEventNames[eventName](eventData)
                else
                    error("WARNING: schedule event called that doesn't exist: '" .. eventName .. "' id: '" .. instanceId .. "' at tick: " .. tick)
                end
            end
            eventName, instances = nextEventName, nextInstances
        end
    end
end

--- Loops over the scheduled once events and runs the actionFunction against each entry with the filter arguments.
---
--- If an actionFunction returns a single "result" item that's not nil then the looping is stopped early. Single "result" values of nil and all "results" values continue the loop.
---@param targetEventName string
---@param targetInstanceId string|number
---@param targetTick? uint
---@param actionFunction fun(tickEvents: UtilityScheduledEvent_ScheduledFunctionsTicksEventNames, targetEventName: string, targetInstanceId: string|number, tick?:uint):UtilityScheduledEvent_ScheduledFunctions_ActionFunctionOutcome? # Function must return a single result and a table of results, both can be nil or populated.
---@return boolean|UtilityScheduledEvent_Information? result # The result type is based on the actionFunction passed in. However nil may be returned if the actionFunction finds no matching results for any reason.
---@return UtilityScheduledEvent_Information[]|uint[] results # A table of the results found or an empty table if nothing matching found.
EventScheduler._ParseScheduledOnceEvents = function(targetEventName, targetInstanceId, targetTick, actionFunction)
    local result
    local results = {} ---@type UtilityScheduledEvent_Information[]|uint[]
    if global.UTILITYSCHEDULEDFUNCTIONS ~= nil then
        if targetTick == nil then
            for tick, tickEvents in pairs(global.UTILITYSCHEDULEDFUNCTIONS) do
                local outcome = actionFunction(tickEvents, targetEventName, targetInstanceId, tick)
                if outcome ~= nil then
                    result = outcome.result
                    if outcome.results ~= nil then
                        results[#results + 1] = outcome.results
                    end
                    if result then
                        break
                    end
                end
            end
        else
            local tickEvents = global.UTILITYSCHEDULEDFUNCTIONS[targetTick]
            if tickEvents ~= nil then
                local outcome = actionFunction(tickEvents, targetEventName, targetInstanceId, targetTick)
                if outcome ~= nil then
                    result = outcome.result
                    if outcome.results ~= nil then
                        results[#results + 1] = outcome.results
                    end
                end
            end
        end
    end
    return result, results
end

--- Returns if there's a scheduled event for this tick's event that matches the filter arguments.
---@param tickEvents UtilityScheduledEvent_ScheduledFunctionsTicksEventNames
---@param targetEventName string
---@param targetInstanceId string|number
---@return UtilityScheduledEvent_ScheduledFunctions_ActionFunctionOutcome? resultObject # Returns either a table with result of TRUE if the event is scheduled or nil. As nil allows the parsing function to continue looking, while TRUE will stop the looping.
EventScheduler._IsEventScheduledOnceInTickEntry = function(tickEvents, targetEventName, targetInstanceId)
    if tickEvents[targetEventName] ~= nil and tickEvents[targetEventName][targetInstanceId] ~= nil then
        return { result = true }
    end
end

--- Removes any scheduled event from this tick's events that matches the filter arguments.
---@param tickEvents UtilityScheduledEvent_ScheduledFunctionsTicksEventNames
---@param targetEventName string
---@param targetInstanceId string|number
---@param tick uint
---@return UtilityScheduledEvent_ScheduledFunctions_ActionFunctionOutcome? resultObject # The number of events removed from this tick.
EventScheduler._RemoveScheduledOnceEventsFromTickEntry = function(tickEvents, targetEventName, targetInstanceId, tick)
    local removedEntriesCount = 0

    -- Check if this tick has any schedules for the filter event name.
    local tickNamedEvent = tickEvents[targetEventName]
    if tickNamedEvent ~= nil then
        -- Check if this tick's filtered event name has any schedules with the filter instance Id.
        if tickNamedEvent[targetInstanceId] ~= nil then
            -- Remove the scheduled filtered scheduled event.
            tickNamedEvent[targetInstanceId] = nil
            removedEntriesCount = removedEntriesCount + 1

            -- Check if the there's no other instances of this scheduled event name.
            if next(tickNamedEvent) == nil then
                -- Remove the table we have just emptied.
                tickEvents[targetEventName] = nil

                -- If there aren't any events for this tick now remove the entry.
                if next(tickEvents) == nil then
                    global.UTILITYSCHEDULEDFUNCTIONS[tick] = nil
                end
            end
        end
    end

    -- Return the count or nil. We don't want to return 0 for every tick as it will just make pointless table entries.
    if removedEntriesCount > 0 then
        return { results = removedEntriesCount } --[[@as UtilityScheduledEvent_ScheduledFunctions_ActionFunctionOutcome]]
    else
        return nil
    end
end

--- Returns information on a matching filtered scheduled event as a UtilityScheduledEvent_Information object.
---@param tickEvents UtilityScheduledEvent_ScheduledFunctionsTicksEventNames
---@param targetEventName string
---@param targetInstanceId string|number
---@param tick uint
---@return UtilityScheduledEvent_ScheduledFunctions_ActionFunctionOutcome? resultObject # Returns either an outcome object with results populated with details on a matching scheduled event or nil if no results.
EventScheduler._GetScheduledOnceEventsFromTickEntry = function(tickEvents, targetEventName, targetInstanceId, tick)
    if tickEvents[targetEventName] ~= nil and tickEvents[targetEventName][targetInstanceId] ~= nil then
        ---@type UtilityScheduledEvent_Information
        local scheduledEvent = {
            tick = tick,
            eventName = targetEventName,
            instanceId = targetInstanceId,
            eventData = tickEvents[targetEventName][targetInstanceId]
        }
        return { results = scheduledEvent }
    end
end

--- Loops over the scheduled each tick events and runs the actionFunction against each entry with the filter arguments.
---
--- If an actionFunction returns a single "result" item that's not nil then the looping is stopped early. Single "result" values of nil and all "results" values continue the loop.
---@param targetEventName string
---@param targetInstanceId string|number
---@param actionFunction fun(tickEvents: UtilityScheduledEvent_ScheduledFunctionsTicksEventNames, targetEventName: string, targetInstanceId: string|number, tick?:uint):UtilityScheduledEvent_ScheduledFunctions_ActionFunctionOutcome? # Function must return a single result and a table of results, both can be nil or populated.
---@return boolean|UtilityScheduledEvent_Information|nil result? # The result type is based on the actionFunction passed in. However nil may be returned if the actionFunction finds no matching results for any reason.
---@return UtilityScheduledEvent_Information[]|uint[] results # A table of the results found or an empty table if nothing matching found.
EventScheduler._ParseScheduledEachTickEvents = function(targetEventName, targetInstanceId, actionFunction)
    local result
    local results = {} ---@type UtilityScheduledEvent_Information[]|uint[]
    if global.UTILITYSCHEDULEDFUNCTIONSPERTICK ~= nil then
        local outcome = actionFunction(global.UTILITYSCHEDULEDFUNCTIONSPERTICK, targetEventName, targetInstanceId)
        if outcome ~= nil then
            result = outcome.result
            if outcome.results ~= nil then
                results[#results + 1] = outcome.results
            end
        end
    end
    return result, results
end

--- Returns if there's a scheduled event for every tick that matches the filter arguments.
---@param everyTickEvents UtilityScheduledEvent_ScheduledFunctionsPerTickEventNamesInstanceIds
---@param targetEventName string
---@param targetInstanceId string|number
---@return UtilityScheduledEvent_ScheduledFunctions_ActionFunctionOutcome? resultObject # Returns either a table with a result of TRUE if found or nil. As nil allows the parsing function to continue looking, while TRUE will stop the looping.
EventScheduler._IsEventScheduledInEachTickList = function(everyTickEvents, targetEventName, targetInstanceId)
    if everyTickEvents[targetEventName] ~= nil and everyTickEvents[targetEventName][targetInstanceId] ~= nil then
        return { result = true }
    end
end

--- Removes any scheduled event from the every tick events that matches the filter arguments.
---@param everyTickEvents UtilityScheduledEvent_ScheduledFunctionsPerTickEventNamesInstanceIds
---@param targetEventName string
---@param targetInstanceId string|number
---@return UtilityScheduledEvent_ScheduledFunctions_ActionFunctionOutcome? resultObject # The number of events removed from this tick.
EventScheduler._RemoveScheduledEventFromEachTickList = function(everyTickEvents, targetEventName, targetInstanceId)
    local removedEntriesCount = 0

    -- Check if there's any schedules for the filter event name in the every tick events list.
    local namedEvent = everyTickEvents[targetEventName]
    if namedEvent ~= nil then
        -- Check if this tick's filtered event name has any schedules with the filter instance Id.
        if namedEvent[targetInstanceId] ~= nil then
            -- Remove the scheduled filtered scheduled event.
            namedEvent[targetInstanceId] = nil
            removedEntriesCount = removedEntriesCount + 1

            -- Check if the there's no other instances of this scheduled event name.
            if next(namedEvent) == nil then
                everyTickEvents[targetEventName] = nil
            end
        end
    end

    -- Return the count or nil. We don't want to return 0 for every tick as it will just make pointless table entries.
    if removedEntriesCount > 0 then
        return { results = removedEntriesCount } --[[@as UtilityScheduledEvent_ScheduledFunctions_ActionFunctionOutcome]]
    else
        return nil
    end
end

--- Returns information on a matching filtered scheduled event as a UtilityScheduledEvent_Information object.
---@param everyTickEvents UtilityScheduledEvent_ScheduledFunctionsPerTickEventNamesInstanceIds
---@param targetEventName string
---@param targetInstanceId string|number
---@return UtilityScheduledEvent_ScheduledFunctions_ActionFunctionOutcome? resultObject # Returns either an outcome object with results populated with details on a matching scheduled event or nil if no results.
EventScheduler._GetScheduledEventFromEachTickList = function(everyTickEvents, targetEventName, targetInstanceId)
    if everyTickEvents[targetEventName] ~= nil and everyTickEvents[targetEventName][targetInstanceId] ~= nil then
        ---@type UtilityScheduledEvent_Information
        local scheduledEvent = {
            eventName = targetEventName,
            instanceId = targetInstanceId,
            eventData = everyTickEvents[targetEventName][targetInstanceId]
        }
        return { results = scheduledEvent }
    end
end

---@alias UtilityScheduledEvent_ScheduledFunctionsTicks table<uint, UtilityScheduledEvent_ScheduledFunctionsTicksEventNames>
---@alias UtilityScheduledEvent_ScheduledFunctionsTicksEventNames table<string, UtilityScheduledEvent_ScheduledFunctionsTicksEventNamesInstanceIds>
---@alias UtilityScheduledEvent_ScheduledFunctionsTicksEventNamesInstanceIds table<string|number, UtilityScheduledEvent_EventData>

---@alias UtilityScheduledEvent_ScheduledFunctionsPerTickEventNames table<string, UtilityScheduledEvent_ScheduledFunctionsPerTickEventNamesInstanceIds>
---@alias UtilityScheduledEvent_ScheduledFunctionsPerTickEventNamesInstanceIds table<string|number, UtilityScheduledEvent_EventData>

---@class UtilityScheduledEvent_ScheduledFunctions_ActionFunctionOutcome
---@field result? boolean
---@field results? UtilityScheduledEvent_Information|uint

return EventScheduler
