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
                    player.print {"api-error.must-be-admin", data.name}
                end
            end
        end
    end
    commands.add_command(name, helpText, handlerFunction)
end

function Commands.GetArgumentsFromCommand(parameter)
    local args = {}
    if parameter ~= nil then
        for i in string.gmatch(parameter or "nil", "%S+") do
            table.insert(args, i)
        end
    end
    return args
end

return Commands
