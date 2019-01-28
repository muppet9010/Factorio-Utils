local Logging = {}

function Logging.PositionToString(position)
	if position == nil then return "nil position" end
	return "(" .. position.x .. ", " .. position.y ..")"
end

function Logging.Log(text)
	if game ~= nil then
		game.write_file("Biter_Attack_Waves_logOutput.txt", tostring(text) .. "\r\n", true)
	end
end

function Logging.LogPrint(text)
	if game ~= nil then
		game.print(tostring(text))
	end
	Logging.Log(text)
end

return Logging
