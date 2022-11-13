--[[
    Events is used to register one or more functions to be run when a script.event occurs.
    It supports defines.events and custom events. Also offers a raise event method.
    Intended for use with a modular script design to avoid having to link to each modular functions in a centralised event handler.
--]]

--[[
    CODE NOTES:
    - This has been typed, but the greyness between defines.events being a number, custom event uints and custom names as strings has caused some confusion in it. If refactoring the internal code try and clear this all up after proper review and testing.
    - eventName is used to distinguish between eventId. With eventName being what is specified at usage and can be a string or a defines enum. With eventId being used when we will have a Factorio unique Id for a specific event. In some cases eventName can be this eventId, but this is only confirmed within these functions and so as a parameter it always maintains this ambiguity.
]]

local TableUtils = require("utility.helper-utils.table-utils")

local Events = {} ---@class Utility_Events
MOD = MOD or {} ---@class MOD
MOD.eventsById = MOD.eventsById or {} ---@type table<defines.events|uint, UtilityEvents_EventHandlerObject[]>
MOD.eventIdHandlerNameToEventIdsListIndex = MOD.eventIdHandlerNameToEventIdsListIndex or {} ---@type table<defines.events|uint, table<string, int>> A way to get the id key from MOD.eventsById for a specific event id and handler name.
MOD.eventFilters = MOD.eventFilters or {} ---@type table<defines.events|uint, table<string, EventFilter[]>>
MOD.customEventNameToId = MOD.customEventNameToId or {} ---@type table<string|defines.events, uint>
MOD.eventsByActionName = MOD.eventsByActionName or {} ---@type table<string, UtilityEvents_EventHandlerObject[]>
MOD.eventActionNameHandlerNameToEventActionNamesListIndex = MOD.eventActionNameHandlerNameToEventActionNamesListIndex or {} ---@type table<string, table<string, int>> # A way to get the id key from MOD.eventsByActionName for a specific action name and handler name.

--------------------------------------------------------------------------------------------
--                                    Public Functions
--------------------------------------------------------------------------------------------

--- Called from OnLoad() from each script file. Registers the event in Factorio and the handler function for all event types and custom events.
---@param eventName defines.events|string|uint # Either Factorio event, a custom modded event name our mod created, or a custom event Id from another mod.
---@param handlerName string # Unique name of this event handler instance. Used to avoid duplicate handler registration and if removal is required.
---@param handlerFunction fun(eventData: EventData) # The function that is called when the event triggers. When the function is called it will receive the standard single Factorio event specific data table argument, which is at a minimum the EventData class.
---@param thisFilterData? EventFilter[] # List of Factorio EventFilters the mod should receive this eventName occurrences for or nil for all occurrences. If an empty table (not nil) is passed in then nothing is registered for this handler (silently rejected). Filtered events have to expect to receive results outside of their own filters. As a Factorio event type can only be subscribed to one time with a combined Filter list of all desires across the mod.
---@return uint? registeredEventId # The eventId raised for this handler (if one was). Useful for custom event names when you need to store the eventId to return via a remote interface call.
Events.RegisterHandlerEvent = function(eventName, handlerName, handlerFunction, thisFilterData)
    if eventName == nil or handlerName == nil or handlerFunction == nil then
        error("Events.RegisterHandlerEvent called with missing arguments")
    end
    local eventId = Events._RegisterEvent(eventName, handlerName, thisFilterData)
    if eventId == nil then
        return nil
    end
    local eventIdHandlers = MOD.eventIdHandlerNameToEventIdsListIndex[eventId]
    if eventIdHandlers == nil or eventIdHandlers[handlerName] == nil then
        -- Is the first registering of this unique handler name for this event id.
        local eventsByIdEntry = MOD.eventsById[eventId]
        if eventsByIdEntry == nil then
            eventsByIdEntry = {}
            MOD.eventsById[eventId] = eventsByIdEntry
        end
        eventsByIdEntry[#eventsByIdEntry + 1] = { handlerName = handlerName, handlerFunction = handlerFunction }
        if eventIdHandlers == nil then
            eventIdHandlers = {}
            MOD.eventIdHandlerNameToEventIdsListIndex[eventId] = eventIdHandlers
        end
        eventIdHandlers[handlerName] = #eventsByIdEntry
    else
        -- Is a re-registering of a unique handler name for this event id, so just update everything.
        MOD.eventsById[eventId][eventIdHandlers[handlerName]] = { handlerName = handlerName, handlerFunction = handlerFunction }
    end
    return eventId
end

--- Called from OnLoad() from each script file. Registers the custom inputs (key bindings) as their names in Factorio and the handler function for all just custom inputs. These are handled specially in Factorio.
---@param actionName string # custom input name (key binding).
---@param handlerName string # Unique handler name.
---@param handlerFunction fun(eventData: CustomInputEvent) # Function to be triggered on action.
Events.RegisterHandlerCustomInput = function(actionName, handlerName, handlerFunction)
    if actionName == nil then
        error("Events.RegisterHandlerCustomInput called with missing arguments")
    end
    local actionNameHandlers = MOD.eventActionNameHandlerNameToEventActionNamesListIndex[actionName]
    if actionNameHandlers == nil or actionNameHandlers[handlerName] == nil then
        -- Is the first registering of this unique handler name for this action name.
        local eventsByActionEntry = MOD.eventsByActionName[actionName]
        if eventsByActionEntry == nil then
            -- First handler for this action.
            eventsByActionEntry = {}
            MOD.eventsByActionName[actionName] = eventsByActionEntry
            script.on_event(actionName, Events._HandleEvent)
        end
        eventsByActionEntry[#eventsByActionEntry + 1] = { handlerName = handlerName, handlerFunction = handlerFunction }
        if actionNameHandlers == nil then
            actionNameHandlers = {}
            MOD.eventActionNameHandlerNameToEventActionNamesListIndex[actionName] = actionNameHandlers
        end
        actionNameHandlers[handlerName] = #eventsByActionEntry
    else
        -- Is a re-registering of a unique handler name for this action name, so just update everything.
        MOD.eventsByActionName[actionName][actionNameHandlers[handlerName]] = { handlerName = handlerName, handlerFunction = handlerFunction }
    end
end

--- Called from OnLoad() from the script file. Registers the custom event name and returns an event ID for use by other mods in subscribing to custom events.
---@param eventName string
---@return uint eventId # Bespoke event id for this custom event.
Events.RegisterCustomEventName = function(eventName)
    if eventName == nil then
        error("Events.RegisterCustomEventName called with missing arguments")
    end
    local eventId
    if MOD.customEventNameToId[eventName] ~= nil then
        eventId = MOD.customEventNameToId[eventName]
    else
        eventId = script.generate_event_name()
        MOD.customEventNameToId[eventName] = eventId
    end
    return eventId
end

--- Called when needed.
---@param eventName defines.events|string|uint # Either Factorio event, a custom modded event name our mod created, or a custom event Id from another mod.
---@param handlerName string # The unique handler name to remove from this eventName.
Events.RemoveHandler = function(eventName, handlerName)
    if eventName == nil or handlerName == nil then
        error("Events.RemoveHandler called with missing arguments")
    end
    local eventsByIdForEventName = MOD.eventsById[eventName--[[@as defines.events|uint]] ]
    if eventsByIdForEventName ~= nil then
        ---@cast eventName - string # Isn't a string value.
        for handlerIndex, handler in pairs(eventsByIdForEventName) do
            if handler.handlerName == handlerName then
                -- Handler found by name so remove it.
                table.remove(eventsByIdForEventName, handlerIndex)

                -- Remove the eventHandlers table if this was the last one in there.
                if next(eventsByIdForEventName) == nil then
                    MOD.eventsById[eventName] = nil
                end

                -- Remove this handlers entry from the MOD.eventIdHandlerNameToEventIdsListIndex[eventId] lookup table.
                local eventIdHandlerNameToEventIdsList = MOD.eventIdHandlerNameToEventIdsListIndex[eventName]
                eventIdHandlerNameToEventIdsList[handlerName] = nil

                -- Update the other handlers for this event in the MOD.eventIdHandlerNameToEventIdsListIndex[eventId] lookup table as the other handlers after the one we just removed will have had their index in the main MOD.eventsById[eventName] table reduced.
                if next(eventIdHandlerNameToEventIdsList) == nil then
                    -- We just removed the only handler for the event, so tidy up this lookup table.
                    MOD.eventIdHandlerNameToEventIdsListIndex[eventName] = nil
                else
                    -- Other handlers still in the lookup table, so update the indexes that are after the one we just removed by reducing them by one. As the table they referenced that we removed an entry from was an array.
                    for otherLookupHandlerName, otherLookupHandlerIndex in pairs(eventIdHandlerNameToEventIdsList) do
                        if otherLookupHandlerIndex > handlerIndex then
                            eventIdHandlerNameToEventIdsList[otherLookupHandlerName] = otherLookupHandlerIndex - 1
                        end
                    end
                end

                -- Remove our handlers filter data.
                local eventFilterHandlers = MOD.eventFilters[eventName]
                eventFilterHandlers[handlerName] = nil

                -- Update the filters for this event based on the remaining handlers.
                if next(eventFilterHandlers) == nil then
                    -- No other handlers for this event, so remove our registrations for it.
                    script.on_event(eventName, nil, nil)
                    MOD.eventFilters[eventName] = nil
                else
                    -- Other handlers on the event, so consider an updated merged filters for them and apply it.
                    local filterData = Events._MakeCombinedEventFilters(eventName)
                    script.set_event_filter(eventName--[[@as uint]] , filterData)
                end

                -- We removed our handler so done.
                return
            end
        end
    else
        local eventsByActionForEventName = MOD.eventsByActionName[eventName--[[@as string]] ]
        if eventsByActionForEventName ~= nil then
            ---@cast eventName string # Is a string value.
            for handlerIndex, handler in pairs(eventsByActionForEventName) do
                if handler.handlerName == handlerName then
                    table.remove(eventsByActionForEventName, handlerIndex)

                    -- Remove the eventHandlers table if this was the last one in there.
                    if next(eventsByActionForEventName) == nil then
                        MOD.eventsByActionName[eventName] = nil
                        -- We can also unsubscribe from the event in this case.
                        script.on_event(eventName, nil)
                    end

                    -- Remove this handlers entry from the MOD.eventIdHandlerNameToEventIdsListIndex[eventId] lookup table.
                    local eventActionHandlerNameToEventActionsList = MOD.eventActionNameHandlerNameToEventActionNamesListIndex[eventName]
                    eventActionHandlerNameToEventActionsList[handlerName] = nil

                    -- Update the other handlers for this event in the MOD.eventActionNameHandlerNameToEventActionNamesListIndex[eventId] lookup table as the other handlers after the one we just removed will have had their index in the main MOD.eventsByActionName[eventName] table reduced.
                    if next(eventActionHandlerNameToEventActionsList) == nil then
                        -- We just removed the only handler for the event, so tidy up this lookup table.
                        MOD.eventActionNameHandlerNameToEventActionNamesListIndex[eventName] = nil
                    else
                        -- Other handlers still in the lookup table, so update the indexes that are after the one we just removed by reducing them by one. As the table they referenced that we removed an entry from was an array.
                        for otherLookupHandlerName, otherLookupHandlerIndex in pairs(eventActionHandlerNameToEventActionsList) do
                            if otherLookupHandlerIndex > handlerIndex then
                                eventActionHandlerNameToEventActionsList[otherLookupHandlerName] = otherLookupHandlerIndex - 1
                            end
                        end
                    end

                    -- We removed our handler so done.
                    return
                end
            end
        end
    end
end

--- Called when needed, but not before tick 0 as they are ignored. Can either raise a custom registered event registered by Events.RegisterCustomEventName(), or one of the limited events defined in the API: https://lua-api.factorio.com/latest/LuaBootstrap.html#LuaBootstrap.raise_event.
---@param eventName defines.events|string|uint # Either Factorio event, a custom modded event name our mod created, or a custom event Id from another mod.
---@param data table # The fields that need to be populated for the given event. Do not need to provide `tick` or `mod_name` as they will be generated by Factorio automatically.
Events.RaiseEvent = function(eventName, data)
    if type(eventName) == "number" then
        script.raise_event(eventName--[[@as uint]] , data)
    elseif MOD.customEventNameToId[eventName] ~= nil then
        script.raise_event(MOD.customEventNameToId[eventName--[[@as string]] ], data)
    else
        error("WARNING: raise event called that doesn't exist: " .. eventName)
    end
end

--- Called from anywhere, including OnStartup in tick 0. This won't be passed out to other mods however, only run within this mod.
---
--- This calls this mod's event handler bypassing the Factorio event system.
---@param eventData EventData # If the `tick` field isn't populated it will be obtained via a Factorio API call.
Events.RaiseInternalEvent = function(eventData)
    eventData.tick = eventData.tick or game.tick --- Technically this can be provided as part of the eventData being raised, but if not we will obtain and add it.
    local eventName = eventData.name
    if type(eventName) == "number" then
        Events._HandleEvent(eventData)
    elseif MOD.customEventNameToId[eventName] ~= nil then
        eventData.name = MOD.customEventNameToId[eventName] --[[@as defines.events # Is just a higher number than the defines.]]
        Events._HandleEvent(eventData)
    else
        error("WARNING: raise event called that doesn't exist: " .. eventName)
    end
end

--------------------------------------------------------------------------------------------
--                                    Internal Functions
--------------------------------------------------------------------------------------------

--- Runs when an event is triggered and calls all of the appropriate registered functions.
---@param eventData EventData
Events._HandleEvent = function(eventData)
    -- input_name only populated by custom_input, with eventId used by all other events
    -- CODE NOTE: Numeric for loop is faster than pairs and this logic is black boxed from code developer using library.
    if eventData["input_name"] == nil then
        -- All non custom input events (majority).
        local eventsById = MOD.eventsById[eventData.name--[[@as defines.events|uint # In a non custom input event code block, but can't cast object field.]] ]
        for i = 1, #eventsById do
            eventsById[i].handlerFunction(eventData)
        end
    else
        -- Custom Input type event.
        local eventsByInputName = MOD.eventsByActionName[eventData.input_name--[[@as string # In a non custom input event code block, but can't cast object field.]] ]
        for i = 1, #eventsByInputName do
            eventsByInputName[i].handlerFunction(eventData)
        end
    end
end

--- Registers the function in to the mods event to function matrix. Handles merging filters between multiple functions on the same event.
---@param eventName defines.events|string|uint # Either Factorio event, a custom modded event name our mod created, or a custom event Id from another mod.
---@param thisFilterName string # The handler name.
---@param thisFilterData? EventFilter[]
---@return uint? eventId
Events._RegisterEvent = function(eventName, thisFilterName, thisFilterData)
    if eventName == nil then
        error("Events.RegisterEvent called with missing arguments")
    end
    local eventId ---@type uint
    local filterData ---@type EventFilter[]|nil
    if type(eventName) == "number" then
        -- Factorio event or a custom event from another mod.
        eventId = eventName --[[@as uint]]
        thisFilterData = thisFilterData ~= nil and TableUtils.DeepCopy(thisFilterData) or {} -- DeepCopy it so if a persisted or shared table is passed in we don't cause changes to source table.

        MOD.eventFilters[eventId] = MOD.eventFilters[eventId] or {}

        --Record the additional filter data to our lists.
        MOD.eventFilters[eventId][thisFilterName] = thisFilterData

        -- Check what is currently recorded for this event to work out how to handle this new filterData.
        local currentFilter, currentHandler = script.get_event_filter(eventId), script.get_event_handler(eventId)
        if currentHandler ~= nil and currentFilter == nil then
            -- An event is registered already and has no filter, so already fully lenient.
            return eventId
        else
            -- Generate new merged filters for all handlers on this event.
            filterData = Events._MakeCombinedEventFilters(eventName)
        end
    elseif MOD.customEventNameToId[eventName] ~= nil then
        -- Already registered custom event created by our mod.
        ---@cast eventName string # As the other event sources would be numeric and caught before.
        eventId = MOD.customEventNameToId[eventName]
    else
        -- New custom event created by our mod.
        ---@cast eventName string # As the other event sources would be numeric and caught before.
        eventId = script.generate_event_name()
        MOD.customEventNameToId[eventName] = eventId
    end

    script.on_event(eventId, Events._HandleEvent, filterData)
    return eventId
end

--- Makes a combined filter[] for all of the handlers we have against a specific event.
---@param eventId defines.events|uint
---@return EventFilter[]|nil eventFilters # Returns nil if no filter should be applied to the Factorio Event registration.
Events._MakeCombinedEventFilters = function(eventId)
    local filterData = {} ---@type EventFilter[]
    for _, filtersTable in pairs(MOD.eventFilters[eventId]) do
        ---@cast filtersTable EventFilter_Base[]
        if next(filtersTable) == nil then
            -- No filter on this handler, so the entire event will be unfiltered.
            return nil
        end
        filtersTable[1].mode = "or" -- The `mode` relates to how it views the previous filter, and we want that to always be an `or` so that we can have multiple separate filters all triggering the event to be raised.
        for _, filterEntry in pairs(filtersTable) do
            filterData[#filterData + 1] = filterEntry
        end
    end
    return filterData
end

return Events

---@class UtilityEvents_EventHandlerObject
---@field handlerName string
---@field handlerFunction function
