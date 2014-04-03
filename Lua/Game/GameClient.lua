Engine.Class.GameClientSocket = {
	__parent = "DataSocket"
}

local Game = {}
Game.hostname = "localhost"
Game.port = "5150"

function GameClientSocket:onDisconnect()
	print("Lost connected to server. Shutting down!")
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
	end
end

function GameClientSocket:onConnect()
	print("Connected to server!")
end

function Client() -- rename to Client later on :)
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
				print("A field is empty!")
			else
				print("Connecting as:", Username.field.text, Password.field.text)
				local socket, err = ConnectToServer(Game.hostname, Game.port)
				if err then
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
	while Game.state == "lobby" do 
		--STUFF
		if Exit:Clicked() then
			CleanUp()
			return nil
		elseif Stats:Clicked() and not Game.TryJoin then
			CleanUp()
			return "stats"
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
	local StatusMsg = BaseText:new{x=300, y = 50, w = 200, h = 30, align = "cm", fontSize=25, text="COUNT"}
	local Player = {}
	Player[1] = BaseText:new{x=50, y = 80, w = 200, h = 30, align = "cm", fontSize=25, text="____HOST___"}
	Player[2] = BaseText:new{x=550, y = 80, w = 200, h = 30, align = "cm", fontSize=25, text="___USER____"}
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
		StatusMsg:Remove()
		Player[1]:Remove()
		Player[2]:Remove()
		Objects[1]:Remove()
		Objects[2]:Remove()
		for i=1,4 do line[i]:Remove() end
		for i = 1, 9 do spots[i]:Remove() end
	end
	
	local prevState
	local lastTurn
	while Game.state == "game" do 
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
		
		
		if Game.game.turn == 1 then
			Player[1].color = 0xFF00FF00
			Player[2].color = 0xFFFFFFFF
		elseif Game.game.turn == 2 then
			Player[2].color = 0xFF00FF00
			Player[1].color = 0xFFFFFFFF
		else
			Player[2].color = 0xFFFFFFFF
			Player[1].color = 0xFFFFFFFF
		end
		if lastTurn ~= Game.game.turn then
			Player[1]:Update()
			Player[2]:Update()
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
	if Game.game == "rageQuit" then
		local RQ = Button:new{x=200, y = 200, w = 400, h = 50, colorBG = 0xFFFF0000, 
							colorText = 0xFF000000, fontName="Lucida Console", text="RAGE QUIT"}
		Engine.SleepRoutine(5000)
		RQ:Remove()
	elseif Game.game == "win" then
		local RQ = Button:new{x=200, y = 200, w = 400, h = 50, colorBG = 0xFF00FF00, 
							colorText = 0xFF000000, fontName="Lucida Console", text="YOU WIN"}
		Engine.SleepRoutine(5000)
		RQ:Remove()
	elseif Game.game == "lose" then
		local RQ = Button:new{x=200, y = 200, w = 400, h = 50, colorBG = 0xFFFF0000, 
							colorText = 0xFF000000, fontName="Lucida Console", text="YOU LOSE"}
		Engine.SleepRoutine(5000)
		RQ:Remove()
	elseif Game.game == "draw" then
		local RQ = Button:new{x=200, y = 200, w = 400, h = 50, colorBG = 0xFFFF00FF, 
							colorText = 0xFF000000, fontName="Lucida Console", text="DRAW"}
		Engine.SleepRoutine(5000)
		RQ:Remove()
	end
	return Game.state
end

--Main
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

end

function RequestGame(gameID)

end

--[[

--]]