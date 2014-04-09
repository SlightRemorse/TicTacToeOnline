local SensitiveMap = 
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
}

local InsensitiveMap =
{
	[2] = '1',
	[3] = '2',
	[4] = '3',
	[5] = '4',
	[6] = '5',
	[7] = '6',
	[8] = '7',
	[9] = '8',
	[10] = '9',
	[11] = '0',
	
	[57] = ' ',
	
	-- num pad
	
	[71] = '7',
	[72] = '8',
	[73] = '9',
	
	[75] = '4',
	[76] = '5',
	[77] = '6',
	
	[79] = '7',
	[80] = '8',
	[81] = '9',
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
	
	if Engine.GetKeyState(14) then return -1 end
	
	for k, v in pairs(InsensitiveMap) do
		if Engine.GetKeyState(k) then
			if not KeyMaskMap[k] then
				ch = string.char(string.byte(v))
	
				if not input then 
					input = ch 
				else
					input = input .. ch
				end
			end
			KeyMaskMap[k] = true
			
		else
			KeyMaskMap[k] = false
		end
	end
	
	for k, v in pairs(SensitiveMap) do
		if Engine.GetKeyState(k) then
			if not KeyMaskMap[k] then
				ch = string.char(string.byte(v)-32*caps)
				
				if not input then 
					input = ch 
				else
					input = input .. ch
				end
			end
			KeyMaskMap[k] = true
			
		else
			KeyMaskMap[k] = false
		end
	end
	
	return input
end