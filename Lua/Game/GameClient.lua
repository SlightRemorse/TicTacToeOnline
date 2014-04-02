local Game = {}
Game.hostname = "localhost"
Game.port = "5150"

function MainLuaLoop() -- rename to Client later on :)
	Engine.SetWindowTitle("Tic Tac Toe Online v0")
	
	Game.state = "game" -- default is login
	
	if not LoadResources() then
		print("Failed to load resources. Make sure you have the /asset/ folder.")
		return
	end
	
	Engine.CreateRoutine(function()
		while true do
			Engine.SockProcessQueue()
			Engine.SleepRoutine(15)
		end
	end)
	local result
	while true do
		if Game.state == "login" then
			Game.state = LoginScreen()
		elseif Game.state == "lobby" then
			Game.state = Lobby()
		elseif Game.state == "game" then
			Game.state = GameScreen()
		else
			return
		end
	end
end

function LoadResources()
	local LoadTexture = function (filename)
		Engine.LoadTextureFile(filename)
		local state, err = Engine.CheckTexture(filename)
		while err == "still loading" do
			Engine.SleepRoutine(100)
			state, err = Engine.CheckTexture(filename)
		end
		return state
	end
	
	return LoadTexture("assets/O.png") and LoadTexture("assets/X.png")
end



function LoginScreen()
	local Username = {}
	Username.text = BaseText:new{x=150, y = 280, w = 200, h = 40, align = "cm", fontSize=25, text="Username:"}
	Username.field = TextField:new{x = 150, y = 320, w=200, h=30}
	local Password = {}
	Password.text = BaseText:new{x=450, y = 280, w = 200, h = 40, align = "cm", fontSize=25, text="Password:"}
	Password.field = TextField:new{x = 450, y = 320, w=200, h=30}
	local Connect = Button:new{x = 340, y=380, w = 120, h = 30, colorBG = 0xAAFFFFFF, text="Connect", fontName="Lucida Console"}
	local Banner = {}
	Banner.large = BaseText:new{x = 0, w = 800, y = 20, h = 180, align = "cm", fontSize=120, text="Tic Tac Toe", color = 0xFF483D8B}
	Banner.small = BaseText:new{x = 0, w = 800, y = 200, h = 60, align = "cm", fontSize=55, text="ONLINE", color = 0xFF483D8B}
	
	local CleanUp = function()
		Username.text:Remove()
		Username.field:Remove()
		Password.text:Remove()
		Password.field:Remove()
		Connect:Remove()
		Banner.large:Remove()
		Banner.small:Remove()
	end
	
	while true do 
		--STUFF
		if Username.field:Clicked() then
			Password.field.Focused = false
			Username.field.Focused = true
		elseif Password.field:Clicked() then
			Password.field.Focused = true
			Username.field.Focused = false
		elseif Connect:Clicked() then
			if not Username.field.text or not Password.field.text then
				print("A field is empty")
			else
				print("CONNECT!", Username.field.text, Password.field.text)
				ConnectToServer(Game.hostname, Game.port)
				LoginServer(Username.field.text, Password.field.text)
				
				if true then
					CleanUp()
					return "lobby"
				end
			end
		end
		
		Engine.SleepRoutine(100)
	end
end

function Lobby()
	local Banner = {}
	Banner.large = BaseText:new{x = 0, w = 800, y = 20, h = 100, align = "c", fontSize=75, text="Lobby", color = 0xFF483D8B}
	Banner.small = BaseText:new{x = 0, w = 800, y = 130, h = 70, align = "cm", fontSize=45, text="Games", color = 0xFFAA99CC}
	local Exit = Button:new{x = 650, y=550, w = 120, h = 30, colorBG = 0xFF8800AA, colorText = 0xAAFFFFFF, text="Exit", fontName="Lucida Console"}
	local Stats = Button:new{x = 500, y=550, w = 120, h = 30, colorBG = 0xFFAA0088, colorText = 0xAAFFFFFF, text="Stats", fontName="Lucida Console"}
	
	local Games = {}
	for i = 1, 8 do
		Games[i] = Button:new{x=150, y = 160+40*i, w = 500, h = 30, colorBG = 0xFFFFFAF0, colorText = 0xBB000000, text = i, fontName="Lucida Console", state = false}
	end
	RequestLobbyData()
	
	local CleanUp = function()
		Banner.large:Remove()
		Banner.small:Remove()
		Exit:Remove()
		Stats:Remove()
		for i = 1, 8 do
			Games[i]:Remove()
		end
	end
	
	local refresh = 0
	while true do 
		--STUFF
		if Exit:Clicked() then
			CleanUp()
			return nil
		elseif Stats:Clicked() then
			CleanUp()
			return "stats"
		end
		
		refresh = refresh + 1
		
		if refresh>20 then -- refresh every ~ 2 sec
			refresh = 0
			RequestLobbyData()
		end
		
		
		Engine.SleepRoutine(100)
	end
end

local FieldSpots = {
			[0] = {x1 = 250, x2=350, y1 = 150, y2 = 250},
			[1] = {x1 = 350, x2=450, y1 = 150, y2 = 250},
			[2] = {x1 = 450, x2=550, y1 = 150, y2 = 250},

			[3] = {x1 = 250, x2=350, y1 = 250, y2 = 350},
			[4] = {x1 = 350, x2=450, y1 = 250, y2 = 350},
			[5] = {x1 = 500, x2=550, y1 = 250, y2 = 350},

			[6] = {x1 = 250, x2=350, y1 = 350, y2 = 450},
			[7] = {x1 = 350, x2=450, y1 = 350, y2 = 450},
			[8] = {x1 = 450, x2=550, y1 = 350, y2 = 450},
}

function GameScreen()
	local StatusMsg = BaseText:new{x=300, y = 50, w = 200, h = 30, align = "cm", fontSize=25, text="COUNT"}
	local Player = {}
	Player[1] = BaseText:new{x=50, y = 80, w = 200, h = 30, align = "cm", fontSize=25, text="____HOST___"}
	Player[2] = BaseText:new{x=550, y = 80, w = 200, h = 30, align = "cm", fontSize=25, text="___USER____"}
	local Objects = {}
	Objects[1] = BaseSprite:new{x=100, y = 150, w = 100, h = 100, texture="assets/X.png"}
	Objects[2] = BaseSprite:new{x=600, y = 150, w = 100, h = 100, texture="assets/O.png"}
	
	local fields = {}
	fields[1] = BaseLine:new{x1=250, x2=550, y1=250, y2=250}
	fields[2] = BaseLine:new{x1=250, x2=550, y1=350, y2=350}
	fields[3] = BaseLine:new{x1=350, x2=350, y1=150, y2=450}
	fields[4] = BaseLine:new{x1=450, x2=450, y1=150, y2=450}
	
	
	while true do 
		--STUFF
		
		Engine.SleepRoutine(100)
	end
end



--Main
function ConnectToServer(hostname, port)

end

function LoginServer(username, password)

end

--Lobby
function RequestLobbyData()

end

function ConnectToGame(gameID)

end

--Game
function SendMove(moveInfo)

end

--Stats
function RequestGameList()

end

function RequestGame(gameID)

end

--[[

--]]