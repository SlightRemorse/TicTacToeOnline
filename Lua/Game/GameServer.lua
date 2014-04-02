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

function GameServerSocket:onReceive(msg)
	local cmd, args = DeserializeMessage(msg)
	print("Command:", cmd)
	if args then
		print("Args:", args[1], args[2], args[3])
	end
	
	if cmd == "Login" then
		if self.state ~= "login" or not args  then
			print("DISCONNECT HIM!")
			return
		end
		
		local SuccessfulLogin = function()
			self:Send(SerializeMessage("Login", "logged"))
			self.user = args[1]
			self.state = "lobby"
		end
		
		if not Users[args[1]] then
			Users[args[1]] = {Password = args[2]}
			SaveUsers(SerializeUsers(Users))
			SuccessfulLogin()
		else
			if args[2] == Users[args[1]].Password then
				SuccessfulLogin()
			else
				self:Send(SerializeMessage("Login", "failed"))
			end
		end
	elseif cmd == "ListGames" then
		if self.state ~= "lobby" or args  then
			print("DISCONNECT HIM!")
			return
		end
		
		local result = {}
		for i=1, 8 do
			if Server.Rooms[i] then
				if Server.Rooms[i].Player2 then
					result[2*i-1] = 2
					result[2*i] = Server.Rooms[i].Player1 .. " vs " .. Server.Rooms[i].Player2
				else
					result[2*i-1] = 1
					result[2*i] = Server.Rooms[i].Player1 .. " vs you?"
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
			print("DISCONNECT HIM!")
			return
		end
		
		if not Server.Rooms[i] then
			--Create game
			self:Send(SerializeMessage("JoinRoom", 1))
		elseif not Server.Rooms[i].Player2 then
			--Join Game
			self:Send(SerializeMessage("JoinRoom", 2))
		else
			--Error, maybe you got raced, don't DC
			self:Send(SerializeMessage("JoinRoom", "failed"))
		end
	end
end



function GameServer() -- rename to Server later on :)
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
	print(Users, SerializeTable(Users))
end

function SaveUsers(str)
	for i=1, #str do print(str[i]) end
	local file = io.open("Users.txt", "w")
	if file then
		for i=1, #str do
			file:write(str[i] .. "\n")
		end
		file:flush()
		file:close()
	end
end

--[[
Сървър сокета ще има специално дефиниран тип сокет, който разраства базовия и поддържа хункционалностите нужни за изпълнението на длъжностите си. Тук нещата ще разчитат още повече на OnReceive event-а и спрямо даден msg ще се изпълнява дадена функция.

AuthenticatePlayer(socket, username); - когато msg-а сигнализира, че иска да се свърже с нас.
ConnectPlayerToGame(socket, gameID); - връзва ни към играта
ListGames(socket); - дава ни игрите

AddMove(socket, moveInfo); - записва хода, праща го на другия играч като обновление и т.н.

GetStats(socket, optional); - сървър страна на RequestStats(), която ще прегледа записаните до сега игри (най-вероятно в xml или друг лесен за четене формат)
GetGameList(socket) - същото, но за RequestGameList()
GetGame(socket, gameID); - ...



OnDisconnect(); - ще се грижи при изключване на даден потребител да бъде спряна играта (ако е почната) или просто да се освободи сокета (ако няма нищо важно започнато)
RecordGame(gameID); - ще записва дадената игра във файл.
--]]