Engine.Class.GameClientSocket = {
	__parent = "DataSocket"
}

local Game = {}
Game.hostname = "localhost"
Game.port = "5150"

function GameClientSocket:onDisconnect()
	print("Lost connection to server. Shutting down!")
	Game.state = nil
end

function GameClientSocket:onReceive(msg)
	local cmd, args = DeserializeMessage(msg)
	print("Command:", cmd)
	if args then
		print("Args:", args[1], args[2], args[3])
	end
	
	if cmd == "Login" then
		if Game.state ~= "login" or not args then
			print("Disconnecting!")
			self:Disconnect()
			Game.state = nil
			return
		end
		if args[1] == "logged" then
			Game.state = "lobby"
			print("Connected. Moving to Lobby.")
		else
			Game.Error.text = args[1]
			Game.Error:Update()
			print("Connection:", args[1])
		end	
	elseif cmd == "ListGames" then
		if Game.state ~= "lobby" or not args then	
			print("DISCONNECT HIM!")
			return
		end
		
		for i=1, 8 do
			Game.Rooms[i].text = args[2*i]
			Game.Rooms[i].state = args[2*i-1]
			Game.Rooms[i]:Update()
		end
		
	elseif cmd == "JoinRoom" then
		if Game.state ~= "lobby" or not args  then
			print("Disconnecting!")
			self:Disconnect()
			Game.state = nil
			return
		end
		
		if args[1] == "host" then
			Game.state = "game"
			Game.you = 1
			Game.game = CreateGame()
			Game.game.Player1 = Game.user
			Game.game.Player2 = ""
		elseif args[1] == "join" then
			Game.state = "game"
			Game.you = 2
			Game.game = CreateGame()
			Game.game.Player1 = args[2]
			Game.game.Player2 = Game.user
		else -- full game
			print("Game is full!")
		end
		
		Game.TryJoin = false

	elseif cmd == "PlayerJoined" then
		if Game.state ~= "game" or not args  then
			print("Disconnecting!")
			self:Disconnect()
			Game.state = nil
			return
		end
		Game.game.Player2 = args[1]
	elseif cmd == "rageQuit" then
		if Game.state ~= "game" or args  then
			print("Disconnecting!")
			self:Disconnect()
			Game.state = nil
			return
		end
		Game.game = cmd
		Game.state = "lobby"
	elseif cmd == "Start" then
		if Game.state ~= "game" or not args  then
			print("Disconnecting!")
			self:Disconnect()
			Game.state = nil
			return
		end
		
		local first = tonumber(args[1])
		if first == 1 then
			Game.game.turn = 1
		else
			Game.game.turn = 2
		end
	elseif cmd == "Move" then
		if Game.state ~= "game" or not args  then
			print("Disconnecting!")
			self:Disconnect()
			Game.state = nil
			return
		end
		
		local spot = tonumber(args[2])
		Game.game[spot] = args[1]
		if Game.game.turn == 1 then Game.game.turn = 2 else Game.game.turn = 1 end
	elseif cmd == "End" then
		if Game.state ~= "game" or not args  then
			print("Disconnecting!")
			self:Disconnect()
			Game.state = nil
			return
		end
		
		if (args[1] == "o" and Game.you == 2) or (args[1] == "x" and Game.you == 1) then
			Game.game = "win"
		elseif	(args[1] == "o" and Game.you == 1) or (args[1] == "x" and Game.you == 2) then
			Game.game = "lose"
		elseif args[1] == "draw" then
			Game.game = args[1]
		end
		
		Game.state = "lobby"
	elseif cmd == "GetHistory" then
		if Game.state ~= "lobby" then
			print("Disconnecting!")
			self:Disconnect()
			Game.state = nil
			return
		end
		if not args then args = {} end
		Game.OldGames = args
		Game.state = "stats"
	elseif cmd == "Request" then
		if Game.state ~= "stats" then
			print("Disconnecting!")
			self:Disconnect()
			Game.state = nil
			return
		end
		if not args then 
			Game.Replay = false 
		else
			TempTable = false
			local chunk = loadstring("TempTable = " .. args[1])
			if chunk then chunk() end
			Game.Replay = TempTable
		end
		if Game.Replay then
			Game.state = "watch"
		end
	end
end

function GameClientSocket:onConnect()
	print("Connected to server!")
end

function Client()
	Engine.SetWindowTitle("Tic Tac Toe Online v0")
	
	Game.state = "login" -- default is login
	
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
		elseif Game.state == "stats" then
			Game.state = History()
		elseif Game.state == "watch" then
			Game.state = WatchGame()
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
	Game.Error = BaseText:new{x=300, y=430, w = 200, h = 30, align = "cm", fontStyle="b", fontSize=20, color = 0xFF990000, text = ""}
	local CleanUp = function()
		Username.text:Remove()
		Username.field:Remove()
		Password.text:Remove()
		Password.field:Remove()
		Connect:Remove()
		Banner.large:Remove()
		Banner.small:Remove()
		
		if Game.Error then
			Game.Error:Remove()
			Game.Error = nil
		end
	end
	
	while Game.state == "login" do 
		--STUFF
		if Username.field:Clicked() then
			Password.field.Focused = false
			Username.field.Focused = true
		elseif Password.field:Clicked() then
			Password.field.Focused = true
			Username.field.Focused = false
		elseif Connect:Clicked() then
			if not Username.field.text or not Password.field.text then
				Game.Error.text = "empty field"
				Game.Error:Update()
				print("A field is empty!")
			else
				print("Connecting as:", Username.field.text, Password.field.text)
				local socket, err = ConnectToServer(Game.hostname, Game.port)
				if err then
					Game.Error.text = "unable to connect"
					Game.Error:Update()
					print("Unable to connect!")
				else
					Game.socket = socket -- from now on we use this socket
					
					LoginServer(Username.field.text, Password.field.text)
				end
			end
		end
		Engine.SleepRoutine(100)
	end
	Game.user = Username.field.text
	Engine.SetWindowTitle("Tic Tac Toe Online v0 User: " .. Game.user)
	CleanUp()
	return Game.state
end

function Lobby()
	local Banner = {}
	Banner.large = BaseText:new{x = 0, w = 800, y = 20, h = 100, align = "c", fontSize=75, text="Lobby", color = 0xFF483D8B}
	Banner.small = BaseText:new{x = 0, w = 800, y = 130, h = 70, align = "cm", fontSize=45, text="Games", color = 0xFFAA99CC}
	local Exit = Button:new{x = 650, y=550, w = 120, h = 30, colorBG = 0xFF8800AA, colorText = 0xAAFFFFFF, text="Exit", fontName="Lucida Console"}
	local Stats = Button:new{x = 500, y=550, w = 120, h = 30, colorBG = 0xFFAA0088, colorText = 0xAAFFFFFF, text="History", fontName="Lucida Console"}
	
	Game.Rooms = {}
	Game.TryJoin = false
	for i = 1, 8 do
		Game.Rooms[i] = Button:new{x=150, y = 160+40*i, w = 500, h = 30, colorBG = 0xFFFFFAF0, colorText = 0xBB000000, text = "LOADING", fontName="Lucida Console", state = false}
	end
	RequestLobbyData()
	
	local CleanUp = function()
		Banner.large:Remove()
		Banner.small:Remove()
		Exit:Remove()
		Stats:Remove()
		for i = 1, 8 do
			Game.Rooms[i]:Remove()
		end
		Game.Rooms = nil
	end
	
	local refresh = 0
	local exitImmunity = true
	Engine.CreateRoutine(function() Engine.SleepRoutine(1000) exitImmunity = false end)
	while Game.state == "lobby" do 
		--STUFF
		if Exit:Clicked() and not exitImmunity then
			CleanUp()
			return nil
		elseif Stats:Clicked() and not Game.TryJoin then
			RequestGameList()
			refresh = -15
		end
		
		for i=1, 8 do
			if Game.Rooms[i].state ~= 2 and Game.Rooms[i]:Clicked() then
				ConnectToGame(i)
				refresh = 0 -- make sure we don't do 2 requests simultaneously
			end
		end
		refresh = refresh + 1
		
		if refresh>20 and not Game.TryJoin then -- refresh every ~ 2 sec
			refresh = 0
			RequestLobbyData()
		end
		
		Engine.SleepRoutine(100)
	end
	CleanUp()
	return Game.state
end

local FieldSpots = {
			[1] = {x1 = 250, x2=350, y1 = 150, y2 = 250},
			[2] = {x1 = 350, x2=450, y1 = 150, y2 = 250},
			[3] = {x1 = 450, x2=550, y1 = 150, y2 = 250},

			[4] = {x1 = 250, x2=350, y1 = 250, y2 = 350},
			[5] = {x1 = 350, x2=450, y1 = 250, y2 = 350},
			[6] = {x1 = 450, x2=550, y1 = 250, y2 = 350},

			[7] = {x1 = 250, x2=350, y1 = 350, y2 = 450},
			[8] = {x1 = 350, x2=450, y1 = 350, y2 = 450},
			[9] = {x1 = 450, x2=550, y1 = 350, y2 = 450},
}

function Clicked()
	local x, y = Engine.GetMousePos(true)
	for i=1, 9 do
		if x >= FieldSpots[i].x1 and x <=FieldSpots[i].x2 and y >=FieldSpots[i].y1 and y <=FieldSpots[i].y2 then
			return i
		end
	end
	return false
end

function GameScreen()
	local StatusMsg = BaseText:new{x=300, y = 50, w = 200, h = 60, align = "cm", fontSize=25, text="WAIT\nFOR PLAYER"}
	local Player = {}
	Player[1] = BaseText:new{x=50, y = 80, w = 200, h = 30, align = "cm", fontSize=25, text="____HOST___"}
	Player[2] = BaseText:new{x=550, y = 80, w = 200, h = 30, align = "cm", fontSize=25, text="___USER____"}
	local Objects = {}
	Objects[1] = BaseSprite:new{x=100, y = 150, w = 100, h = 100, texture="assets/X.png"}
	Objects[2] = BaseSprite:new{x=600, y = 150, w = 100, h = 100, texture="assets/O.png"}
	
	local Back = Button:new{x = 650, y=550, w = 120, h = 30, colorBG = 0xFF8800AA, colorText = 0xAAFFFFFF, text="Quit", fontName="Lucida Console"}
	
	
	local line = {}
	line[1] = BaseLine:new{x1=250, x2=550, y1=250, y2=250}
	line[2] = BaseLine:new{x1=250, x2=550, y1=350, y2=350}
	line[3] = BaseLine:new{x1=350, x2=350, y1=150, y2=450}
	line[4] = BaseLine:new{x1=450, x2=450, y1=150, y2=450}
	
	local spots = {}
	for i = 1, 9 do
		spots[i] = BaseSprite:new{x = FieldSpots[i].x1, y = FieldSpots[i].y1, w = 100, h = 100, texture=false, state = false}
	end
	
	local CleanUp = function()
		StatusMsg:Remove()
		Player[1]:Remove()
		Player[2]:Remove()
		Objects[1]:Remove()
		Objects[2]:Remove()
		Back:Remove()
		for i=1,4 do line[i]:Remove() end
		for i = 1, 9 do spots[i]:Remove() end
	end
	
	local prevState
	local lastTurn
	while Game.state == "game" do 
		if Back:Clicked() then
			CleanUp()
			QuitCurrentGame()
			return Game.state
		end
		--STUFF
		if Player[1].text ~= Game.game.Player1 then
			Player[1].text = Game.game.Player1
			Player[1]:Update()
		end
		if Player[2].text ~= Game.game.Player2 then
			Player[2].text = Game.game.Player2
			Player[2]:Update()
		end
		
		for i = 1, 9 do 
			if Game.game[i] ~= spots[i].state then
				spots[i].state = Game.game[i]
				if Game.game[i] == "o" then
					spots[i].texture = "assets/O.png"
				elseif Game.game[i] == "x" then
					spots[i].texture = "assets/X.png"
				else
					spots[i].texture = false
				end
				spots[i]:Update()
			end
		end
		
		if lastTurn ~= Game.game.turn then
			Player[1]:Update()
			Player[2]:Update()
		end
		
		if Game.game.turn == Game.you then
			StatusMsg.color = 0xFF00FF00
			StatusMsg.text = "YOUR\nTURN"
			StatusMsg:Update()
		elseif Game.game.turn then
			StatusMsg.color = 0xFFFFFFFF
			StatusMsg.text = "HIS\nTURN"
			StatusMsg:Update()
		end
		lastTurn = Game.game.turn
		
		local key = false
		if Game.game.turn == Game.you then
			local KeyState = Engine.GetButtonState(1)
			
			if KeyState and KeyState ~= prevState then
				key = Clicked()
			end
			prevState = KeyState
		end
		if key then
			SendMove(key)
		end
		Engine.SleepRoutine(100)
	end
	
	CleanUp()
	local RQ
	if Game.game == "rageQuit" then
		RQ = Button:new{x=200, y = 200, w = 400, h = 50, colorBG = 0xFFFF0000, 
							colorText = 0xFF000000, fontName="Lucida Console", text="RAGE QUIT"}
	elseif Game.game == "win" then
		RQ = Button:new{x=200, y = 200, w = 400, h = 50, colorBG = 0xFF00FF00, 
							colorText = 0xFF000000, fontName="Lucida Console", text="YOU WIN"}
	elseif Game.game == "lose" then
		RQ = Button:new{x=200, y = 200, w = 400, h = 50, colorBG = 0xFFFF0000, 
							colorText = 0xFF000000, fontName="Lucida Console", text="YOU LOSE"}
	elseif Game.game == "draw" then
		RQ = Button:new{x=200, y = 200, w = 400, h = 50, colorBG = 0xFFFF00FF, 
							colorText = 0xFF000000, fontName="Lucida Console", text="DRAW"}
	end
	Engine.SleepRoutine(5000)
	RQ:Remove()
	
	return Game.state
end

function QuitCurrentGame()
	Game.socket:Send(SerializeMessage("QuitGame"))
	Game.state = "lobby"
end

function ConnectToServer(hostname, port)
	local sock = GameClientSocket:new{}
	local err = sock:Connect(hostname, port)
	if err then 
		--socket cleanup here?
		return nil, err
	end
	return sock, err
end

function LoginServer(username, password)
	Game.socket:Send(SerializeMessage("Login", username, password))
end

--Lobby
function RequestLobbyData()
	Game.socket:Send(SerializeMessage("ListGames"))
end

function ConnectToGame(gameID)
	print("Connect me to", gameID)
	Game.TryJoin = gameID
	Game.socket:Send(SerializeMessage("JoinRoom", gameID))
end

--Game
function SendMove(moveInfo)
	Game.socket:Send(SerializeMessage("Move", moveInfo))
end

--Stats
function RequestGameList()
	Game.socket:Send(SerializeMessage("GetHistory"))
end

function RequestGame(id)
	Game.socket:Send(SerializeMessage("Request", id))
end

function History()
	local Banner = {}
	Banner.large = BaseText:new{x = 0, w = 800, y = 20, h = 100, align = "c", fontSize=75, text=Game.user.."'s", color = 0xFF483D8B}
	Banner.small = BaseText:new{x = 0, w = 800, y = 130, h = 70, align = "cm", fontSize=45, text="History", color = 0xFFAA99CC}
	local Back = Button:new{x = 650, y=550, w = 120, h = 30, colorBG = 0xFF8800AA, colorText = 0xAAFFFFFF, text="Back", fontName="Lucida Console"}
	
	local prevButton = {x = 15, w = 120, y = 340, h = 30, colorBG = 0xFF881144, colorText = 0xAAFFFFFF, text="PREV", fontName="Lucida Console"}
	local nextButton = {x = 665, w = 120, y = 340, h = 30, colorBG = 0xFF881144, colorText = 0xAAFFFFFF, text="NEXT", fontName="Lucida Console"}
	
	local Prev = false
	local Next = false
	
	local Day = Button:new{x = 200, y=550, w = 120, h = 30, colorBG = 0xFFAA0088, colorText = 0xAAFFFFFF, text="Daily", fontName="Lucida Console"}
	local Hour = Button:new{x = 340, y=550, w = 120, h = 30, colorBG = 0xFFAA0088, colorText = 0xAAFFFFFF, text="Hourly", fontName="Lucida Console"}
	local All = Button:new{x = 480, y=550, w = 120, h = 30, colorBG = 0xFFAA0088, colorText = 0xAAFFFFFF, text="All", fontName="Lucida Console"}
	
	Game.Rooms = {}
	for i = 1, 8 do
		Game.Rooms[i] = Button:new{x=150, y = 160+40*i, w = 500, h = 30, colorBG = 0xFFFFFAF0, colorText = 0xBB000000, text = "LOADING", fontName="Lucida Console", state = false}
	end
	
	local CleanUp = function()
		Banner.large:Remove()
		Banner.small:Remove()
		Back:Remove()
		
		Day:Remove()
		Hour:Remove()
		All:Remove()
		
		if Prev then Prev:Remove() end
		if Next then Next:Remove() end
		
		for i = 1, 8 do
			Game.Rooms[i]:Remove()
		end
		Game.Rooms = nil
	end
	
	local CleanUpNav = function()
		if Next then Next:Remove() Next = false end
		if Prev then Prev:Remove() Prev = false end
	end
	
	local GamesShown = {}
	for i = 1, #Game.OldGames do
		GamesShown[i] = Game.OldGames[i]
	end
	
	-- setup view
	
	for i = 1, 8 do
			Game.Rooms[i].text = GamesShown[i]
			Game.Rooms[i]:Update()
	end
	
	if #GamesShown > 8 then
		Next = Button:new(nextButton)
	end
	local page = 0
	
	local Filter = false
	
	local refresh = 0
	while Game.state == "stats" do 
		--STUFF
		if Back:Clicked() then
			CleanUp()
			Game.socket:Send(SerializeMessage("BackToLobby"))
			return "lobby"
		end
		
		if Next then
			if Next:Clicked() then
				page = page + 1
				for i = 1, 8 do
					Game.Rooms[i].text = GamesShown[i+page*8]
					Game.Rooms[i]:Update()
				end	
				Prev = Button:new(prevButton)
				if not GamesShown[(page+1)*8+1] then
						Next:Remove()
						Next = false
				end		
			end
		end
		
		if Prev then
			if Prev:Clicked() then
				page = page - 1
				for i = 1, 8 do
					Game.Rooms[i].text = GamesShown[i+page*8]
					Game.Rooms[i]:Update()
				end	
				Next = Button:new(nextButton)
				if not GamesShown[(page-1)*8+1] then
					Prev:Remove()
					Prev = false
				end
			end
		end
		
		if Day:Clicked() then
			CleanUpNav()
			
			Filter = os.date("games/%y%m%d")
			for i = 1, #GamesShown do GamesShown[i] = nil end
			
			for i = 1, #Game.OldGames do
				local found = string.find(Game.OldGames[i], Filter)
				if found == 1 then
					GamesShown[#GamesShown+1] = Game.OldGames[i]
				end
			end
			for i = 1, 8 do
				Game.Rooms[i].text = GamesShown[i]
				Game.Rooms[i]:Update()
			end
			if #GamesShown > 8 then
				Next = Button:new(nextButton)
			end
			page = 0
		end
		
		if Hour:Clicked() then
			CleanUpNav()
			
			Filter = os.date("games/%y%m%d%H")
			for i = 1, #GamesShown do GamesShown[i] = nil end
			
			for i = 1, #Game.OldGames do
				local found = string.find(Game.OldGames[i], Filter)
				if found == 1 then
					GamesShown[#GamesShown+1] = Game.OldGames[i]
				end
			end
			for i = 1, 8 do
				Game.Rooms[i].text = GamesShown[i]
				Game.Rooms[i]:Update()
			end
			if #GamesShown > 8 then
				Next = Button:new(nextButton)
			end
			page = 0
		end
		
		if All:Clicked() then
			CleanUpNav()
		
			for i = 1, #GamesShown do GamesShown[i] = nil end
			for i = 1, #Game.OldGames do
				GamesShown[i] = Game.OldGames[i]
			end
			
			for i = 1, 8 do
				Game.Rooms[i].text = GamesShown[i]
				Game.Rooms[i]:Update()
			end
			if #GamesShown > 8 then
				Next = Button:new(nextButton)
			end
			page = 0
		end
		
		
		
		for i=1, 8 do
			if Game.Rooms[i].text and Game.Rooms[i]:Clicked() then
				RequestGame(Game.Rooms[i].text)
			end
		end
		
		Engine.SleepRoutine(100)
	end
	
	CleanUp()
	return Game.state
end

function WatchGame()
	local Player = {}
	Player[1] = BaseText:new{x=50, y = 80, w = 200, h = 30, align = "cm", fontSize=25, text=Game.Replay.Player1}
	Player[2] = BaseText:new{x=550, y = 80, w = 200, h = 30, align = "cm", fontSize=25, text=Game.Replay.Player2}
	local StatusMsg = BaseText:new{x=300, y = 50, w = 200, h = 30, align = "cm", fontSize=25}
	local Objects = {}
	Objects[1] = BaseSprite:new{x=100, y = 150, w = 100, h = 100, texture="assets/X.png"}
	Objects[2] = BaseSprite:new{x=600, y = 150, w = 100, h = 100, texture="assets/O.png"}
	
	local line = {}
	line[1] = BaseLine:new{x1=250, x2=550, y1=250, y2=250}
	line[2] = BaseLine:new{x1=250, x2=550, y1=350, y2=350}
	line[3] = BaseLine:new{x1=350, x2=350, y1=150, y2=450}
	line[4] = BaseLine:new{x1=450, x2=450, y1=150, y2=450}
	
	local spots = {}
	for i = 1, 9 do
		spots[i] = BaseSprite:new{x = FieldSpots[i].x1, y = FieldSpots[i].y1, w = 100, h = 100, texture=false, state = false}
	end
	
	local CleanUp = function()
		Player[1]:Remove()
		Player[2]:Remove()
		Objects[1]:Remove()
		Objects[2]:Remove()
		StatusMsg:Remove()
		for i=1,4 do line[i]:Remove() end
		for i = 1, 9 do spots[i]:Remove() end
	end

	for i=1, #Game.Replay do
		--play a move
		Engine.SleepRoutine(1500)
		local t = Game.Replay[i]
		StatusMsg.text = i
		StatusMsg:Update()
		if t.Player == "o" then 
			Player[1].color = 0xFF00FF00
			Player[2].color = 0xFFFFFFFF
			spots[t.Spot].texture = "assets/O.png"
			spots[t.Spot]:Update()
		else
			Player[2].color = 0xFF00FF00
			Player[1].color = 0xFFFFFFFF
			spots[t.Spot].texture = "assets/X.png"
			spots[t.Spot]:Update()
		end
		Player[1]:Update()
		Player[2]:Update()
	end
	if Game.Replay.state == "draw" then
		StatusMsg.text = "DRAW"
	else
		if Game.Replay.state == "rageQuit" then
			if Game.Replay.turn == 2 then
				Player[1].text = "RAGEQUIT"
				Player[1].color = 0xFFFF0000
				Player[1]:Update()
			else
				Player[2].text = "RAGEQUIT"
				Player[2].color = 0xFFFF0000
				Player[2]:Update()
			end
		end
		StatusMsg.text = Player[Game.Replay.turn].text .. " WINS!"
	end
		StatusMsg:Update()
		
	Engine.SleepRoutine(2000)
	CleanUp()
	return "stats" 
end