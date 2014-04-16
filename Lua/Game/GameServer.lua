Engine.Class.GameServerSocket = {
	__parent = "DataSocket",
}

local Server = {}
Server.hostname = "localhost"
Server.port = 5150

function GameServerSocket:onConnect()
	print("Client connected!")
	self.state = "login"
end

local loggedUsers = {}

function RageQuitHandle(self)
	if Server.Rooms[self.gameID].Player1 == self then
		--host left
		if Server.Rooms[self.gameID].Player2 then
			Server.Rooms[self.gameID].state = "rageQuit"
			Server.Rooms[self.gameID].turn = 2
			
			local filename = SaveGame(SerializeGame(Server.Rooms[self.gameID]))
			local ut
			ut = Users[Server.Rooms[self.gameID].Player1.user]
			ut[#ut+1] = filename
			ut = Users[Server.Rooms[self.gameID].Player2.user]
			ut[#ut+1] = filename
			SaveUsers(SerializeUsers(Users))
			
			Server.Rooms[self.gameID].Player2:Send(SerializeMessage("rageQuit"))
			Server.Rooms[self.gameID].Player2.state = "lobby"
		end
		Server.Rooms[self.gameID] = false
	else
		--player 2 left
		Server.Rooms[self.gameID].state = "rageQuit"
		Server.Rooms[self.gameID].turn = 1
		
		local filename = SaveGame(SerializeGame(Server.Rooms[self.gameID]))
		local ut
		ut = Users[Server.Rooms[self.gameID].Player1.user]
		ut[#ut+1] = filename
		ut = Users[Server.Rooms[self.gameID].Player2.user]
		ut[#ut+1] = filename
		SaveUsers(SerializeUsers(Users))
		
		Server.Rooms[self.gameID].Player1:Send(SerializeMessage("rageQuit"))
		Server.Rooms[self.gameID].Player1.state = "lobby"
		Server.Rooms[self.gameID] = false
	end
end

function GameServerSocket:onDisconnect()
	print("Disconnected!", self.user, self.state)
	if self.user then
		loggedUsers[self.user] = nil
	end
	if self.state == "login" then
		--nothing to clean up
	elseif self.state == "lobby" then
		--nothing to clean up
	elseif self.state == "game" then
		RageQuitHandle(self)
	elseif self.state == "stats" then
		--nothing to clean up
	end
end

function GameServerSocket:onReceive(msg)
	local cmd, args = DeserializeMessage(msg)
	print("Command:", cmd)
	if args then
		print("Args:", args[1], args[2], args[3])
	end
	
	if cmd == "Login" then
		if self.state ~= "login" or not args  then
			print("Disconnecting!")
			print(self:Disconnect())
			return
		end
		
		local SuccessfulLogin = function()
			self:Send(SerializeMessage("Login", "logged"))
			self.user = args[1]
			self.state = "lobby"
			loggedUsers[self.user] = true
		end
		
		if not Users[args[1]] then
			Users[args[1]] = {Password = args[2]}
			SaveUsers(SerializeUsers(Users))
			SuccessfulLogin()
		else
			if args[2] == Users[args[1]].Password then
				if loggedUsers[args[1]] then
					self:Send(SerializeMessage("Login", "account in use"))
				else
					SuccessfulLogin()
				end
			else
				self:Send(SerializeMessage("Login", "wrong password"))
			end
		end
	elseif cmd == "ListGames" then
		if self.state ~= "lobby" or args  then
			print("Disconnecting!")
			print(self:Disconnect())
			return
		end
		
		local result = {}
		for i=1, 8 do
			if Server.Rooms[i] then
				if Server.Rooms[i].Player2 then
					result[2*i-1] = 2
					result[2*i] = Server.Rooms[i].Player1.user .. " vs " .. Server.Rooms[i].Player2.user
				else
					result[2*i-1] = 1
					result[2*i] = Server.Rooms[i].Player1.user .. " vs you?"
				end
			else
				result[2*i-1] = 0
				result[2*i] = "open"
			end 
			i = i + 1
		end
		self:Send(SerializeMessage("ListGames", result))
		
	elseif cmd == "JoinRoom" then
		if self.state ~= "lobby" or not args  then
			print("Disconnecting!")
			print(self:Disconnect())
			return
		end
		local id = tonumber(args[1]) -- we receive it as string, but need it as number
		if not Server.Rooms[id] then
			--Create game
			self.state = "game"
			self.gameID = id
			self:Send(SerializeMessage("JoinRoom", "host"))
			Server.Rooms[id] = CreateGame()
			Server.Rooms[id].Player1 = self
			
		elseif not Server.Rooms[id].Player2 then
			--Join Game
			self.state = "game"
			self.gameID = id
			self:Send(SerializeMessage("JoinRoom", "join", Server.Rooms[id].Player1.user))
			Server.Rooms[id].Player2 = self
			
			--notify the other player
			Server.Rooms[id].Player1:Send(SerializeMessage("PlayerJoined", self.user))
			
			--Choose who's first
			local first = Engine.Random(1,2)
			if first == 1 then
				Server.Rooms[id].Player1:Send(SerializeMessage("Start", 1))
				Server.Rooms[id].Player2:Send(SerializeMessage("Start", 1))
			else
				Server.Rooms[id].Player1:Send(SerializeMessage("Start", 2))
				Server.Rooms[id].Player2:Send(SerializeMessage("Start", 2))
			end
			Server.Rooms[id].state = "play"
			Server.Rooms[id].turn = first
		else
			--Error, maybe you got raced, don't DC
			self:Send(SerializeMessage("JoinRoom", "failed"))
		end
	elseif cmd == "Move" then
		if self.state ~= "game" or not args  then
			print("Disconnecting!")
			print(self:Disconnect())
			return
		end
		
		if self == Server.Rooms[self.gameID].Player1 then
			if Server.Rooms[self.gameID].turn == 1 then
				local spot = tonumber(args[1])
				if not Server.Rooms[self.gameID][spot] then
					local th = Server.Rooms[self.gameID].History
					
					th[#th + 1] = { Player = "x", Spot = spot}
					
					Server.Rooms[self.gameID][spot] = "x"
					Server.Rooms[self.gameID].turn = 2
					
					Server.Rooms[self.gameID].Player1:Send(SerializeMessage("Move", "x", spot))
					Server.Rooms[self.gameID].Player2:Send(SerializeMessage("Move", "x", spot))
				end
			end
		elseif self == Server.Rooms[self.gameID].Player2 then
			if Server.Rooms[self.gameID].turn == 2 then
				local spot = tonumber(args[1])
				if not Server.Rooms[self.gameID][spot] then
					local th = Server.Rooms[self.gameID].History
					
					th[#th + 1] = { Player = "o", Spot = spot}
					
					Server.Rooms[self.gameID][spot] = "o"
					Server.Rooms[self.gameID].turn = 1
					
					Server.Rooms[self.gameID].Player1:Send(SerializeMessage("Move", "o", spot))
					Server.Rooms[self.gameID].Player2:Send(SerializeMessage("Move", "o", spot))
				end
			end
		end
		
		local eval = EvaluateGame(Server.Rooms[self.gameID])
		
		if eval then
			Server.Rooms[self.gameID].Player1:Send(SerializeMessage("End", eval))
			Server.Rooms[self.gameID].Player1.state = "lobby"
			Server.Rooms[self.gameID].Player2:Send(SerializeMessage("End", eval))
			Server.Rooms[self.gameID].Player2.state = "lobby"
			--RECORD HISTORY HERE
			if eval == "draw" then
				Server.Rooms[self.gameID].state = "draw"
				Server.Rooms[self.gameID].turn = 0
			else 
				Server.Rooms[self.gameID].state = "win"
				if eval == "o" then 
					Server.Rooms[self.gameID].turn = 2 
				else 
					Server.Rooms[self.gameID].turn = 1 
				end
			end
			
			local filename = SaveGame(SerializeGame(Server.Rooms[self.gameID]))
			local ut
			ut = Users[Server.Rooms[self.gameID].Player1.user]
			ut[#ut+1] = filename
			ut = Users[Server.Rooms[self.gameID].Player2.user]
			ut[#ut+1] = filename
			SaveUsers(SerializeUsers(Users))
			
			
			Server.Rooms[self.gameID] = false
		end
		
	elseif cmd == "GetHistory" then
		if self.state ~= "lobby" or args  then
			print("Disconnecting!")
			print(self:Disconnect())
			return
		end
		
		self.state = "stats"
		local ut = Users[self.user]
		local t = {}
		
		for i = 1, #ut do
			t[i] = ut[i]
		end
		self:Send(SerializeMessage("GetHistory", t))
	
	elseif cmd == "Request" then
		if self.state ~= "stats" or not args  then
			print("Disconnecting!")
			print(self:Disconnect())
			return
		end
		local exists = GetGame(args[1])
		
		if exists then
			self:Send(SerializeMessage("Request", SerializeTable(TempTable)))
		else
			self:Send(SerializeMessage("Request"))
		end
	elseif cmd == "BackToLobby" then
		if self.state ~= "stats" or args  then
			print("Disconnecting!")
			print(self:Disconnect())
			return
		end
		self.state = "lobby"
	elseif cmd == "QuitGame" then
		if self.state ~= "game" or args  then
			print("Disconnecting!")
			print(self:Disconnect())
			return
		end
		RageQuitHandle(self)
		self.state = "lobby"
	end
end

function EvaluateGame(game)	
	for i = 1, 3 do 
		if game[i*3 - 2] == game[i*3 - 1] and game[i*3 - 1] == game[3*i] and game[i*3] ~= false then
			return game[i*3]
		end
		if game[i] == game[i + 3] and game[i + 3] == game[i + 6] and game[i] ~= false then
			return game[i]
		end
	end
	if (game[1] == game[5] and game[1] == game[9]) or
		(game[3] == game[5] and game[5] == game[7]) then
			return game[5]
	end
	if #game.History == 9 then
		return "draw"
	end
	return false
end

function GameServer()
	Engine.SetWindowTitle("Tic Tac Toe Server v0")
	Engine.SetResolution(false, 100, 100)

	Server.socket = ServerSocket:new{socketType = "GameServerSocket"}
	local err = Server.socket:Listen(Server.hostname, Server.port)
	if err then
		print(err)
		return
	end
	
	GetUsers()
	Server.Rooms = {}
	for i = 1, 8 do 
		Server.Rooms[i] = false
	end
	
	while true do
		Engine.SockProcessQueue()
		Engine.SleepRoutine(15)
	end
end

function GetUsers()
	local chunk, err = loadfile("Users.txt")
	
	if chunk then
		chunk()
	end
	
	if type(Users) ~= "table" then
		Users = {}
	end
end

function SaveUsers(str)
	local file = io.open("Users.txt", "w")
	if file then
		for i=1, #str do
			file:write(str[i] .. "\n")
		end
		file:flush()
		file:close()
	end
end

function GetGame(name)
	TempTable = nil
	local chunk, err = loadfile(name)
	
	if chunk then
		chunk()
	end
	
	if type(TempTable) ~= "table" then
		return false
	end
	return true
end

function SaveGame(str)
	local i = 1
	local file = true
	local newfile = false
	
	for i=1, #str do print(str[i]) end
	
	while file do
		newfile = os.date("games/%y%m%d%H%M%S_".. i ..".gam")
		file = io.open(newfile, "r")
		i = i + 1
		if file then 
			file:close()
		end
	end
	
	file = io.open(newfile, "w")
	if file then
		for i=1, #str do
			file:write(str[i] .. "\n")
		end
		file:flush()
		file:close()
		return newfile
	end
	
	return nil
end

function CreateGame()
	local t = {
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
	
	return t
end