local KeyMap = 
{
	[16] = 'q',
	[17] = 'w',
	[18] = 'e',
	[19] = 'r',
	[20] = 't',
	[21] = 'y',
	[22] = 'u',
	[23] = 'i',
	[24] = 'o',
	[25] = 'p',
	
	[30] = 'a',
	[31] = 's',
	[32] = 'd',
	[33] = 'f',
	[34] = 'g',
	[35] = 'h',
	[36] = 'j',
	[37] = 'k',
	[38] = 'l',
	
	[44] = 'z',
	[45] = 'x',
	[46] = 'c',
	[47] = 'v',
	[48] = 'b',
	[49] = 'n',
	[50] = 'm',
	
	[57] = ' ',
	[14] = -1,
	
}

local KeyMaskMap = {}

local LastInput = nil
function GetCharInput()
	local _, caps = Engine.GetKeyState(58)
	if Engine.GetKeyState(42) or Engine.GetKeyState(54) then
		caps = not caps
	end
	if caps then caps = 1 else caps = 0 end
	
	local input = nil
	local ch
	
	for k, v in pairs(KeyMap) do
		if Engine.GetKeyState(k) then
			if not KeyMaskMap[k] then
				
				if k~=57 then
					ch = string.char(string.byte(v)-32*caps)
				else
					ch = string.char(string.byte(v))
				end
				
				if not input then 
					input = ch 
				else
					input = input .. ch
				end
				
				LastInput = k
			end
			KeyMaskMap[k] = true
			
			if k == 14 then
				return -1
			end
			
		else
			if k == LastInput then LastInput = nil end
			KeyMaskMap[k] = false
		end
	end
	ch = KeyMap[LastInput]
	if ch then
		if k~=57 then
			ch = string.char(string.byte(KeyMap[LastInput])-32*caps)
		else
			ch = string.char(string.byte(KeyMap[LastInput]))
		end
	end
	if KeyMaskMap[14] then return -1 end -- backspace
	return input or ch
end