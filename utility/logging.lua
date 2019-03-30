local Logging = {}

function Logging.PositionToString(position)
    if position == nil then
        return "nil position"
    end
    return "(" .. position.x .. ", " .. position.y .. ")"
end

function Logging.Log(text, enabled)
    if enabled ~= nil and not enabled then
        return
    end
    if game ~= nil then
        game.write_file("Inbuilt_Lighting_logOutput.txt", tostring(text) .. "\r\n", true)
    end
end

function Logging.LogPrint(text, enabled)
    if enabled ~= nil and not enabled then
        return
    end
    if game ~= nil then
        game.print(tostring(text))
    end
    Logging.Log(text)
end

return Logging
