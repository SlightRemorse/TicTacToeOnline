Engine.Class.Button =
{
	__rect = false,
	__text = false,
	
	__prevButtonState = false,
	
	x = 0.0,
	y = 0.0,
	w = 0.0,
	h = 0.0,
	colorBG = 0xFF000000,
	
	text = false,
	fontName = "Arial",
	colorText = 0xFFFFFFFF,
	
	Update = function(self)
		self.__rect.x = self.x
		self.__rect.y = self.y
		self.__rect.w = self.w
		self.__rect.h = self.h
		self.__rect.color = self.colorBG
		self.__rect:Update()
		
		self.__text.x = self.x
		self.__text.y = self.y
		self.__text.w = self.w
		self.__text.h = self.h
		self.__text.text = self.text
		self.__text.fontName = self.fontName
		self.__text.fontSize (self.h*0.8)
		self.__text:Update()
		
	end,
	
	Clicked  = function(self)
		if Engine.GetButtonState(1) then
			if self.__prevButtonState == 1 then 
				return false 
			end
			self.__prevButtonState = 1
			
			local x, y = Engine.GetMousePos(true)
			if x >= self.x and x <= self.x+self.w and y >=self.y and y<=self.y+self.h then
				return true
			end
		else
			self.__prevButtonState = 0
		end
		return false
	end,
	
	init = function(self)
		self.__rect = BaseRect:new{x=self.x, y=self.y, w=self.w, h=self.h, color=self.colorBG}
		self.__text = BaseText:new{x=self.x, y=self.y, w=self.w, h=self.h, fontName = self.fontName, fontSize = (self.h*0.8), align = "cm", text = self.text, color = self.colorText}
	end,
}

Engine.Class.TextField = 
{
	__rect = false,
	__text = false,
	__quit = false,
	
	x = 0.0,
	y = 0.0,
	w = 0.0,
	h = 0.0,
	colorBG = 0xFFFFFFFF,
	
	Focus = false,
	text = false,
	fontName = "Arial",
	colorText = 0xFF000000,
	
	Update = function(self)
		__rect.x = self.x
		__rect.y = self.y
		__rect.w = self.w
		__rect.h = self.h
		__rect.color = self.colorBG
		__rect:Update()
		
		__text.x = self.x
		__text.y = self.y
		__text.w = self.w
		__text.h = self.h
		__text.text = self.text
		__text.fontName = self.fontName
		__text.fontSize (self.h*0.8)
		__text:Update()
		
	end,
	
	Clicked  = function(self)
		if Engine.GetButtonState(1) then
			if self.__prevButtonState == 1 then 
				return false 
			end
			self.__prevButtonState = 1
			
			local x, y = Engine.GetMousePos(true)
			if x >= self.x and x <= self.x+self.w and y >=self.y and y<=self.y+self.h then
				return true
			end
		else
			self.__prevButtonState = 0
		end
		return false
	end,
	
	init = function(self)
		self.__rect = BaseRect:new{x=self.x, y=self.y, w=self.w, h=self.h, color=self.colorBG}
		self.__text = BaseText:new{x=self.x, y=self.y, w=self.w, h=self.h, fontName = self.fontName, fontSize = (self.h*0.8), align = "m", text = self.text, color = self.colorText}
		
		Engine.CreateRoutine(function()
			local lastKey = false
			local first = false
			while true do
				local ch = GetCharInput()
				
				if ch then
					if ch == lastKey then
						if first then
							Engine.SleepRoutine(125)
							first = false
						else
							Engine.SleepRoutine(75)
						end
						ch = false
					end
					if ch and self.Focus then
						if ch == -1 then
							local txt = self.__text.text
							local strlen = string.len(txt) -1
							
							if strlen < 0 then strlen = 0 end
							
							txt = string.sub(txt, 1, strlen)
							self.__text.text = txt
						else
							self.__text.text = self.__text.text .. ch
						end
						self.__text:Update()
					end
					
					if self.__quit then return end
					
					if lastKey ~= ch then first = true end
					lastKey = ch
				end
				Engine.SleepRoutine(20)
			end
		end)
	end,
}