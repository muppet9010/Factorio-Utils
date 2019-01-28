local Events = {}

function Events.DoFirst()
    if MOD == nil then MOD = {} end
    if MOD.events == nil then MOD.events = {} end
end

function Events.RegisterEvent(eventName)
	local eventId = script.generate_event_name()
	script.on_event(defines.events.on_player_created, function(eventData) eventData.customName = eventName Events.CallHandler(eventData) end)
end

function Events.RegisterHandler(eventName, handlerName, handlerFunction)
    local eventId = eventName
    if MOD.events[eventId] == nil then MOD.events[eventId] = {} end
    MOD.events[eventId][handlerName] = handlerFunction
end

function Events.RemoveHandler(eventName, handlerName)
    if MOD.events[eventName] == nil then return end
    MOD.events[eventName][handlerName] = nil
end

function Events.CallHandler(eventData)
	local eventId
	if eventData.customName ~= nil then
		eventId = eventData.customName
	else
		eventId = eventData.name
	end
    if MOD.events[eventId] == nil then return end
    for _, handlerFunction in pairs(MOD.events[eventId]) do
        handlerFunction(eventData)
    end
end

function Events.Fire(eventData)
	eventData.tick = game.tick
    local eventName = eventData.name
    if defines.events[eventName] ~= nil then
		script.raise_event(eventName, eventData)
    else
        Events.CallHandler(eventData)
    end
end

return Events
