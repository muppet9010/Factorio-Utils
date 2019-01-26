local Events = {}

function Events.DoFirst()
    if MOD == nil then MOD = {} end
    if MOD.events == nil then MOD.events = {} end
    if MOD.customEvents == nil then MOD.customEvents = {} end
end

function Events.RegisterHandler(eventName, handlerName, handlerFunction)
    local eventId
    if defines.events[eventName] ~= nil then
        eventId = eventName
    elseif MOD.customEvents[eventName] ~= nil then
        eventId = MOD.customEvents[eventName]
    else
        MOD.customEvents[eventName] = script.generate_event_name()
        eventId = MOD.customEvents[eventName]
    end
    if MOD.events[eventName] == nil then MOD.events[eventName] = {} end
    MOD.events[eventName][handlerName] = handlerFunction
end

function Events.RemoveHandler(eventName, handlerName)
    if MOD.events[eventName] == nil then return end
    MOD.events[eventName][handlerName] = nil
end

function Events.CallHandler(eventData)
    local eventName = eventData.name
    if MOD.events[eventName] == nil then return end
    for _, handlerFunction in pairs(MOD.events[eventName]) do
        handlerFunction(eventData)
    end
end

function Events.Fire(eventData)
    local eventName = eventData.name
    local eventId
    if defines.events[eventName] ~= nil then
        eventId = eventName
    elseif MOD.customEvents[eventName] ~= nil then
        eventId = MOD.customEvents[eventName]
    else
        return
    end
    script.raise_event(eventId, eventData)
end

return Events
