function SerializeMessage(...)
	local msg = nil
	for i = 1, select("#",...) do
		local data = select(i, ...)
		if type(data) == "table" then
			for k, v in pairs(data) do
				if not msg then
					msg = v
				else
					msg = msg .. string.char(255) .. v
				end
			end
		else
			if not msg then
				msg = select(i, ...)
			else
				msg = msg .. string.char(255) .. select(i, ...)
			end
		end
    end
	return msg
end

function DeserializeMessage(msg)
	local command, args
	local prev = 1
	local now
	now = string.find(msg, string.char(255), prev)
	if now then
		command = string.sub(msg, prev, now-1)
		prev = now + 1
	else
		command = msg
		return command
	end
	args = {}
	while true do
		now = string.find(msg, string.char(255), prev)
		if now then
			args[#args+1] = string.sub(msg, prev, now-1)
			prev = now + 1
		else
			args[#args+1] = string.sub(msg, prev, string.len(msg))
			return command, args
		end
	end
end

function SerializeTable(t)
	if type(t) ~= "table" then
		return "not a table"
	end
	
	local  str = "{ "
	for k, v in pairs(t) do
		if type(k) == "string" then
			str = str .. k .. " = "
			if type(v) == "table" then
				str = str .. SerializeTable(v) .. ", "
			elseif type(v) == "string" then
				str = str .. "\"" .. v .. "\"" .. ", "
			else 
				str = str .. tostring(v) .. ", "
			end
		else
			str = str .. "[" .. tostring(k) .. "] = "
			if type(v) == "table" then
				str = str .. SerializeTable(v) .. ", "
			elseif type(v) == "string" then
				str = str .. "\"" .. v .. "\"" .. ", "
			else 
				str = str .. tostring(v) .. ", "
			end
		end
	end
	str = string.sub(str, 1, string.len(str)-2)
	if string.len(str) == 0 then
		str = "{}"
	else
		str = str .. " }"
	end
	return str
end

function SerializeUsers(t)
	local str = {}
	str[1] = "Users = {"
	local i = 1
	for k, v in pairs(t) do
		i = i + 1
		str[i] = "\t" .. k .. " = " .. SerializeTable(v) .. ","
	end
	str[i+1] = "}"
	
	return str
end

function SerializeGame(game)
	local str = {}
	str[1] = "TempTable = {"
	
	str[2] = "\t Player1 = \"" .. game.Player1.user .. "\","
	str[3] = "\t Player2 = \"" .. game.Player2.user .. "\","
	
	str[4] = "\t state = \"" .. game.state .. "\","
	str[5] = "\t turn = " .. game.turn .. ","

	local spot = 5
	for i=1 , #game.History do
		str[spot+i] = "\t [" .. i .. "] = " .. SerializeTable(game.History[i]) .. ","
	end
	str[#str+1] = "}"
	
	return str
end

--[[
Player1 = false,
	Player2 = false,
	
	state = "wait",
	
	[1] = false,
	[2] = false,
	[3] = false,
	
	[4] = false,
	[5] = false,
	[6] = false,
	
	[7] = false,
	[8] = false,
	[9] = false,
	
	History = {}
	}
--]]