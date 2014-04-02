function SerializeTable(t)
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
	str = str .. " }"
	return str
end

local test = {
	Vasko = {Password = "potato", [1] = 1231231, [2] = 2321332, options = {[false] = true, [true] = false}}
}

function SerializeUserData(t)
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