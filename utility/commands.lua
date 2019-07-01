local Commands = {}

function Commands.Register(name, helpText, commandFunction, adminOnly)
    commands.remove_command(name)
    local handlerFunction
    if not adminOnly then
        handlerFunction = commandFunction
    elseif adminOnly then
        handlerFunction = function(data)
            if data.player_index == nil then
                commandFunction(data)
            else
                local player = game.get_player(data.player_index)
                if player.admin then
                    commandFunction(data)
                else
                    player.print("Must be an admin to run command: " .. data.name)
                end
            end
        end
    end
    commands.add_command(name, helpText, handlerFunction)
end

--Supports arguments with spaces within single or double quotes. No escaping of quotes within a command needed.
function Commands.GetArgumentsFromCommand(parameterString)
    local args = {}
    local longArg = ""
    if parameterString ~= nil then
        for i in string.gmatch(parameterString or "nil", "%S+") do
            if string.sub(i, 1, 1) == "'" or string.sub(i, 1, 1) == '"' then
                longArg = i
            elseif string.sub(i, -1) == "'" or string.sub(i, -1) == '"' then
                longArg = longArg .. " " .. i
                table.insert(args, Commands._StripLeadingTrailingQuotes(longArg))
                longArg = ""
            elseif longArg ~= "" then
                longArg = longArg .. " " .. i
            else
                table.insert(args, Commands._StripLeadingTrailingQuotes(i))
            end
        end
    end
    return args
end

function Commands._StripLeadingTrailingQuotes(text)
    if string.sub(text, 1, 1) == "'" and string.sub(text, -1) == "'" then
        return string.sub(text, 2, -2)
    elseif string.sub(text, 1, 1) == '"' and string.sub(text, -1) == '"' then
        return string.sub(text, 2, -2)
    else
        return text
    end
end

return Commands
