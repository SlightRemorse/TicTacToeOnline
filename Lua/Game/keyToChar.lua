KeyMap = 
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

local KeyPressMap = {}

local __LastInput = 0
function GetCharInput()
	local _, caps = Engine.GetKeyState(58)
	if Engine.GetKeyState(42) or Engine.GetKeyState(54) then
		caps = not caps
	end
	
	for k, v in pairs(KeyMap) do
		if Engine.GetKeyState(k) then
			
			KeyPressMap[k] = true
			
			if k == 14 then
				return -1
			end
			if caps and k ~= 57 then
				return string.char(string.byte(v)-32)
			else
				return string.char(string.byte(v))
			end
		else
			KeyPressMap[k] = false
		end
	end
	return nil
end