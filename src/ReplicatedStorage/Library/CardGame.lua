local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local CardGame = {}
CardGame.__index = CardGame;
--==
local RunService = game:GetService("RunService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));

local remoteCardGame = modRemotesManager:Get("CardGame");

local GameState = {
	Idle=1;
	Active=2;
	End=3;
	Closed=4;
}

local StageType = {
	NextTurn=1;
	Dispute=2;
	Sacrifice=3;
	AttackDispute=4;
	Break=5;
	SwapCards=6;
	BluffTrial=7;
	BluffConclusion=8;
	PlayerDefeated=9;
}

CardGame.GameState = GameState;
CardGame.StageType = StageType;
CardGame.EmptyCard = {Texture="rbxassetid://10882992323"};
CardGame.Cards = {
	Rouge={Texture="rbxassetid://10862601197"; Color=Color3.fromRGB(140, 82, 82); };
	Zombie={Texture="rbxassetid://10862606629"; Color=Color3.fromRGB(82, 98, 42); };
	Bandit={Texture="rbxassetid://10862607939"; Color=Color3.fromRGB(99, 67, 53); };
	RAT={Texture="rbxassetid://10862614223"; Color=Color3.fromRGB(120, 71, 111); };
	BioX={Texture="rbxassetid://10862615191"; Color=Color3.fromRGB(49, 86, 76); };
}

CardGame.ActionOptions = {
	--== Basic Actions
	{Text="Scavenge (+1-2 Resource)"; SpaceCost=1; BroadcastMsg="$PlayerName scavenged and found $Amount resources."};
	{Text="Heavy Attack (-10 Resource)"; Cost=10; SelectTarget=true; BroadcastMsg="$PlayerName has attacked $TargetName."};
	--== Card Actions
	{Text="Attack (-4 Resource)"; Cost=4; Requires="Rouge"; SelectTarget=true; BroadcastMsg="$PlayerName has attacked $TargetName."};
	{Text="Block Attack"; Requires="_Zombie"; BroadcastMsg="$PlayerName has blocked the attack."};
	
	--5
	{Text="Raid (+2 Resource)"; SpaceCost=2; Requires="Bandit"; SelectTarget=true; RequiresResources=true; BroadcastMsg="$PlayerName has raided $TargetName for $Amount resources."};
	{Text="Smuggle (+3 Resource)"; SpaceCost=3; Requires="RAT"; BroadcastMsg="$PlayerName has smuggled in $Amount extra resources."};
	{Text="Switch Allies (-1 Resource)"; Cost=1; Requires="BioX"; PickCards=true; BroadcastMsg="$PlayerName has decided to switch alliance."};
}

CardGame.Lobbies = {};

--==
local function shuffleArray(array)
	if array == nil then return end;
	local n=#array
	for i=1,n-1 do
		local l= math.random(i, n);
		array[i],array[l]=array[l],array[i]
	end
end

local Lobby = {};
Lobby.__index = Lobby;

function Lobby.new()
	local self = {
		StageIndex = 0;
		State = GameState.Idle;
		Host = nil;
		Players = {};
		Spectators = {};
		StageQueue = {};
		
		CardPool = {};
	};
	
	for cardKey, cardInfo in pairs(CardGame.Cards) do
		for a=1, 3 do
			table.insert(self.CardPool, cardKey);
		end
	end
	shuffleArray(self.CardPool);
	
	setmetatable(self, Lobby);
	return self;
end

function Lobby:GetPlayer(player)
	for a=#self.Players, 1, -1 do
		if self.Players[a].Player == player then
			return self.Players[a], a; -- {Type="Players"};
		end
	end
	
	for a=#self.Spectators, 1, -1 do
		if self.Spectators[a].Player == player then
			return self.Spectators[a], a; -- {Type="Spectators"};
		end
	end
end

function Lobby:SetPlayerType(player, setType)
	local playerTable, tableIndex = self:GetPlayer(player);
	
	if playerTable.Type ~= setType then
		playerTable = table.remove(self[playerTable.Type], tableIndex);
		playerTable.Type = setType;
		table.insert(self[playerTable.Type], playerTable);
		
		if setType == "Players" then
			self:Broadcast(player.Name.." joined the game!");
		end
	end

	self:Changed(true);
end

function Lobby:SetState(gameState)
	self.State = gameState;

	self:Changed(true);
end

function Lobby:QueueStage(stageType, data)
	data = data or {};
	data.Type = stageType;
	
	Debugger:Log("AddStage:", data);
	table.insert(self.StageQueue, data);
	
	Debugger:Log("self.StageQueue", self.StageQueue);
end

function Lobby:Destroy()
	table.clear(self.Players);
	table.clear(self.Spectators);
	table.clear(self);
	
	local lobbyIndex = table.find(CardGame.Lobbies, self);
	if lobbyIndex then
		table.remove(CardGame.Lobbies, lobbyIndex);
		Debugger:Log("Destroyed lobby");
	end
	self.Destroyed = true;
end

function Lobby:UpdateStats(player, isWin)
	task.spawn(function()
		local profile = shared.modProfile:Get(player);
		local cardgamestatsFlag = profile.Flags:Get("cardgamestats") or {Id="cardgamestats";};

		cardgamestatsFlag.Wins = (cardgamestatsFlag.Wins or 0) + (isWin and 1 or 0);
		cardgamestatsFlag.Loses = (cardgamestatsFlag.Loses or 0) + (isWin and 0 or 1);

		profile.Flags:Add(cardgamestatsFlag);
	end)
end

function Lobby:NextTurn()
	local unixTime = DateTime.now().UnixTimestampMillis;
	
	self.ActionPlayed = false;
	self.StageIndex = self.StageIndex +1;
	
	if self.TurnIndex == nil then
		self.TurnIndex = 0;
		
		for a=1, #self.Players do
			local playerTable = self.Players[a];
			playerTable.Cards = {
				table.remove(self.CardPool, 1);
				table.remove(self.CardPool, 1);
			}
			playerTable.R = 0;
		end
		
		self:QueueStage(StageType.NextTurn);
		
	elseif #self.Players == 1 then
		local player = self.Players[1].Player;
		
		task.spawn(function()
			local profile = shared.modProfile:Get(player);
			if profile then
				local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
				modOnGameEvents:Fire("OnFotlWon", player);
				profile:AddPlayPoints(30, "Gameplay:Minigame:Fotl");
			end
		end)

		self:UpdateStats(player, true);
		
		self:Broadcast(player.Name.." has won the game!", {SndId="WestStyleVictory"});
		self:SetState(GameState.End);
		
		self:Destroy();
		
		return;
	end

	local duration = 10;
	
	local stageInfo = self.StageQueue[self.StageIndex];
	if stageInfo == nil then
		self:QueueStage(StageType.NextTurn);
		stageInfo = self.StageQueue[self.StageIndex];
		Debugger:Log("Missing next stage", self.StageIndex);
	end
	
	--===

	if stageInfo.Type == StageType.NextTurn then
		self.TurnIndex = self.TurnIndex+1
		if self.Players[self.TurnIndex] == nil then
			self.TurnIndex = 1;
		end
	end
	
	local turnPlayerTable = self.Players[self.TurnIndex];
	if turnPlayerTable then
		stageInfo.TurnPlayer = turnPlayerTable.Player;
	end
	
	self.Stage = stageInfo;
	Debugger:Log("Stage ",self.StageIndex.."/"..(#self.StageQueue)," NextTurn ", self.Stage.Type);
	
	if stageInfo.Type == StageType.NextTurn then
		self:Broadcast(turnPlayerTable.Player.Name.."'s turn..", {SndId="Notification"});
		duration = 15;
		Debugger:Log("stageInfo.Type == NextTurn");

	elseif stageInfo.Type == StageType.Dispute then
		duration = 3;

	elseif stageInfo.Type == StageType.Sacrifice then
		
	elseif stageInfo.Type == StageType.AttackDispute then
		duration = 10;

	elseif stageInfo.Type == StageType.Break then
		duration = 2;
		Debugger:Log("stageInfo.Type == Break");
		
	elseif stageInfo.Type == StageType.SwapCards then
		duration = 20;
		
	elseif stageInfo.Type == StageType.BluffTrial then
		
		local accuserPlayer = stageInfo.Accuser;
		local defendantPlayer = stageInfo.Defendant; 
		self:Broadcast(accuserPlayer.Name .." has called "..defendantPlayer.Name.."'s bluff.", {SndId="CallBluff"});
		
		Debugger:Log("Bluff trial", stageInfo);
		duration = 2;
		
		self:QueueStage(StageType.BluffConclusion, stageInfo);

	elseif stageInfo.Type == StageType.BluffConclusion then

		Debugger:Log("BluffConclusion stageInfo, ", stageInfo);
		
		local accuserPlayer = stageInfo.Accuser;
		local defendantPlayer = stageInfo.Defendant;
		
		if stageInfo.IsBluff then
			self:Broadcast(defendantPlayer.Name .." was caught bluffing.", {SndId="SoftWin"});
			stageInfo.Loser = defendantPlayer;
			
		else
			self:Broadcast(defendantPlayer.Name.." was actually not bluffing.", {SndId="TempleKnock"});
			stageInfo.Loser = accuserPlayer;
			
		end
		
		local loserPlayerTable = self:GetPlayer(stageInfo.Loser);
		if #loserPlayerTable.Cards <= 1 then
			duration = 2;
			self.ActionPlayed = true;
			self:QueueStage(StageType.PlayerDefeated, {DefeatedPlayer=stageInfo.Loser;});
			
		else
			duration = 10;
		end

	elseif stageInfo.Type == StageType.PlayerDefeated then
		Debugger:Log("stageInfo", stageInfo);
		self:Broadcast(stageInfo.DefeatedPlayer.Name .." was defeated.", {SndId="HardBassDefeat"});
		self:SetPlayerType(stageInfo.DefeatedPlayer, "Spectators");
		duration = 3;

		self:UpdateStats(stageInfo.DefeatedPlayer, false);
		Debugger:Log(stageInfo.DefeatedPlayer.Name,"Defeated", self);
	end

	self.RadialStartTime = unixTime;
	self.RadialEndTime = unixTime+ duration *1000;
	
	local thisStage = self.StageIndex;
	task.delay(duration, function()
		if thisStage ~= self.StageIndex then return end;
		
		if self.ActionPlayed == false then
			local playerTable = self.Players[self.TurnIndex];
			
			if stageInfo.Type == StageType.NextTurn then
				if playerTable.R < 10 then
					self:PlayAction(playerTable.Player, {OptionIndex=1});
					
					return;
					
				else
					local targetOptions = {};
					for a=#self.Players, 1, -1 do
						if self.Players[a].Player ~= playerTable.Player then
							table.insert(targetOptions, self.Players[a].Player);
						end
					end
					
					self:PlayAction(playerTable.Player, {OptionIndex=2; TargetPlayer=targetOptions[math.random(1, #targetOptions)]});

					return;
				end
				
				
			elseif stageInfo.Type == StageType.Dispute then
				if stageInfo.ActionId == 3 then -- Rouge Attack;
					Debugger:Log("Dispute Timeout", stageInfo);
					self:PlayAction(stageInfo.TargettedPlayer, {CallBluff=false;});
					
					return;
				end
				
			elseif stageInfo.Type == StageType.AttackDispute then
				Debugger:Log("AttackDispute Timeout", stageInfo);
				self:PlayAction(stageInfo.Victim, {AttackDisputeChoice=math.random(1, 2)});
				
				return;
				
			elseif stageInfo.Type == StageType.SwapCards then
				Debugger:Log("SwapCards Timeout", stageInfo);
				if playerTable.Player.ClassName == "Player" then
					task.spawn(function()
						remoteCardGame:InvokeClient(playerTable.Player, "swapcards", self.CardSwapSelections);
					end)
				end
				self:PlayAction(playerTable.Player, {PickedCards=self.CardSwapSelections});
				
				return;
				
			elseif stageInfo.Type == StageType.BluffConclusion and stageInfo.Loser then
				Debugger:Log("BluffConclusion Timeout", stageInfo);
				self:PlayAction(stageInfo.Loser, {FoldCard=math.random(1, 2)});
				
				return;
				
			elseif stageInfo.Type == StageType.Sacrifice then
				Debugger:Log("Sacrifice Timeout", stageInfo);
				self:PlayAction(stageInfo.Loser, {FoldCard=math.random(1, 2)});
				
			end
			
			if self.ActionPlayed then
				Debugger:Log("No action played, defaulting", stageInfo);
			end
		end
		
		self:NextTurn();
	end)

	self:Changed(true);
end

function Lobby:PlayAction(player, packet)
	local playerTable = self:GetPlayer(player);
	
	local unixTime = DateTime.now().UnixTimestampMillis;
	local optionIndex = packet.OptionIndex;
	local targetPlayer = packet.TargetPlayer;
	
	local stageInfo = self.StageQueue[self.StageIndex];
	
	Debugger:Log("Stage ",self.StageIndex.."/"..(#self.StageQueue) ," PlayAction ",optionIndex, player, packet);
	self.ActionPlayed = true;
	
	if packet.CallBluff == false then
		if stageInfo.ActionId == 3 then
			Debugger:Log("Accept attack");
			self:QueueStage(StageType.AttackDispute, {Attacker=stageInfo.TurnPlayer; Victim=stageInfo.TargettedPlayer;});

		end
		
		
	elseif packet.FoldCard then
		packet.FoldCard = packet.FoldCard == 1 and 1 or 2;
		
		local loser = stageInfo.Loser;
		local loserPlayerTable = self:GetPlayer(loser);
		
		Debugger:Log("PlayAction fold", loser, packet);
		local card = table.remove(loserPlayerTable.Cards, packet.FoldCard);
		
		self:Broadcast(loser.Name .. " folds ".. card .."!", {SndId="CardGameKilled"});
		self:QueueStage(StageType.Break, {
			StateLog=(loser.Name.." folds "..card);
		});

	elseif packet.AttackDisputeChoice then
		local hasZombieCard = table.find(playerTable.Cards, "Zombie") ~= nil;
		
		Debugger:Log("attackdispute stageInfo", stageInfo, " playerTable", playerTable, " hasZombieCard ", hasZombieCard, " AttackDisputeChoice ", packet.AttackDisputeChoice);
		if #playerTable.Cards <= 1 then
			self:Broadcast(player.Name .. " blocks with Zombie!");
			stageInfo.IsBluff=(not hasZombieCard);
			self:QueueStage(StageType.Dispute, {TargettedPlayer = stageInfo.Attacker; Victim=player; AttackDispute=true; IsBluff=(not hasZombieCard);});

		elseif packet.AttackDisputeChoice == 1 and hasZombieCard then
			self:Broadcast(player.Name .. " blocks with Zombie!");
			stageInfo.IsBluff=false;
			self:QueueStage(StageType.Dispute, {TargettedPlayer = stageInfo.Attacker; Victim=player; AttackDispute=true;});

		elseif packet.AttackDisputeChoice == 2 and not hasZombieCard then -- Bluff zombie block;
			self:Broadcast(player.Name .. " blocks with Zombie!");
			stageInfo.IsBluff=true;
			self:QueueStage(StageType.Dispute, {TargettedPlayer = stageInfo.Attacker; Victim=player; AttackDispute=true; IsBluff=true;});


		else
			self:Broadcast(player.Name .. " has chose to sacrifice.");
			self:QueueStage(StageType.Sacrifice, {TargettedPlayer = player; Loser=player});

		end
		


	elseif optionIndex then
		local optionLib = CardGame.ActionOptions[optionIndex];

		if optionLib.Cost and playerTable.R < optionLib.Cost then
			optionIndex = 1;
			optionLib = CardGame.ActionOptions[optionIndex];
		end

		stageInfo.ActionId = optionIndex;

		local hasCard = table.find(playerTable.Cards, optionLib.Requires);

		local broadcastMsg = optionLib.BroadcastMsg;
		broadcastMsg = string.gsub(broadcastMsg, "$PlayerName", player.Name);

		if optionIndex == 1 then -- Scavenge;
			local rngRAmt = math.random(1,2);
			broadcastMsg = string.gsub(broadcastMsg, "$Amount", "<b>" ..rngRAmt.. "</b>");

			if playerTable.R + rngRAmt > 10 then
				broadcastMsg = player.Name .." could not find any resources.";
				rngRAmt = 0;

			else
				playerTable.R = math.clamp(playerTable.R + rngRAmt, 0, 10);
			end

			self:QueueStage(StageType.Break, {
				StateLog=(player.Name.." scavenged "..rngRAmt);
			});

		elseif optionIndex == 6 then -- Smuggle;
			broadcastMsg = string.gsub(broadcastMsg, "$Amount", "<b>" .. 3 .. "</b>");
			playerTable.R = math.clamp(playerTable.R + 3, 0, 10);

			self:QueueStage(StageType.Dispute, {IsBluff=(not hasCard); ActionId=optionIndex});


		elseif optionIndex == 7 then
			if packet.PickedCards then
				local cardsLeft = #playerTable.Cards;

				local cardOptions = self.CardSwapSelections;
				for a=1, #playerTable.Cards do
					table.insert(cardOptions, playerTable.Cards[a]);
				end
				table.clear(playerTable.Cards);
				self.CardSwapSelections = nil;

				for a=1, math.min(#packet.PickedCards, cardsLeft) do
					local inputCardName = packet.PickedCards[a];
					local cardIndex = table.find(cardOptions, inputCardName);

					if cardIndex then
						table.remove(cardOptions, cardIndex);
						table.insert(playerTable.Cards, inputCardName);
					end
				end

				for a=1, #cardOptions do
					table.insert(self.CardPool, cardOptions[a]);
				end

				playerTable.R = math.clamp(playerTable.R -1, 0, 10);
				Debugger:Log("Picked cards", self);

			else
				self.CardSwapSelections = {
					table.remove(self.CardPool, 1);
					table.remove(self.CardPool, 1);
				};

				self:QueueStage(StageType.SwapCards, {IsBluff=table.find(playerTable.Cards, "BioX") == nil; ActionId=optionIndex;});
				Debugger:Log(self.StageIndex," = ", self.StageQueue);

			end

		elseif optionLib.SelectTarget and targetPlayer then
			local targetPlayerTable = self:GetPlayer(targetPlayer);
			broadcastMsg = string.gsub(broadcastMsg, "$TargetName", targetPlayer.Name);

			if optionIndex == 2 then -- Heavy Attack;
				playerTable.R = math.clamp(playerTable.R -10, 0, 10);

				if #targetPlayerTable.Cards > 1 then
					self:QueueStage(StageType.Sacrifice, {TargettedPlayer = targetPlayer; Loser = targetPlayer;});

				else
					self:QueueStage(StageType.PlayerDefeated, {DefeatedPlayer = targetPlayer;});

				end


			elseif optionIndex == 3 then -- Rouge Attack;
				playerTable.R = math.clamp(playerTable.R -4, 0, 10);
				self:QueueStage(StageType.Dispute, {IsBluff=(not hasCard); ActionId=optionIndex; TargettedPlayer=targetPlayer;});


			elseif optionIndex == 5 then -- Raid;
				if targetPlayerTable.R-2 < 0 then
					targetPlayerTable.R = 0;
					playerTable.R = math.clamp(playerTable.R + 1, 0, 10);
					broadcastMsg = string.gsub(broadcastMsg, "$Amount", "<b>" .. 1 .. "</b>");

				else
					targetPlayerTable.R = targetPlayerTable.R -2;
					playerTable.R = math.clamp(playerTable.R + 2, 0, 10);
					broadcastMsg = string.gsub(broadcastMsg, "$Amount", "<b>" .. 2 .. "</b>");

				end
				self:QueueStage(StageType.Dispute, {IsBluff=(not hasCard); ActionId=optionIndex; TargettedPlayer=targetPlayer;});


			end

		end
		self:Broadcast(broadcastMsg, {ActionId=optionIndex;});
		
		
	end
	
	task.spawn(function()
		local profile = shared.modProfile:Get(player);
		if profile then
			profile:AddPlayPoints(4, "Gameplay:Minigame:Fotl");
		end
	end)

	self:Changed(true);
	self:NextTurn();
end

function Lobby:Broadcast(msg, packet)
	packet = packet or {};
	packet.Text = msg;
	self.BroadcastMsg = packet;

	self:Changed(true)
end

function Lobby:Start()
	if self.State == GameState.Idle then
		self:SetState(GameState.Active);
		self:Broadcast("Match starting...", {SndId="MatchStart"});
		
		task.delay(3, function()
			self:NextTurn();
		end)
	end
end

function Lobby:Join(player)
	local playerTable = self:GetPlayer(player);
	
	if playerTable == nil then
		playerTable = {Type="Spectators"; Player=player};
		table.insert(self.Spectators, playerTable);
	end
	
	self:Changed(true);
end

function Lobby:Leave(player)
	if self.Host == player then
		self:SetState(GameState.Closed);
		self:Destroy();
		
	else
		for a=#self.Players, 1, -1 do
			local playerTable = self.Players[a];
			if playerTable.Player == player then
				table.remove(self.Players, a);
				self:Broadcast(player.Name.." left the game!");

				task.spawn(function()
					if playerTable.Player then
						local profile = shared.modProfile:Get(playerTable.Player);
						if profile and profile.EquippedTools.StorageItem and profile.EquippedTools.StorageItem.ItemId == "fotlcardgame" then
							shared.EquipmentSystem.ToolHandler(playerTable.Player, "unequip");
						end
					end
				end)
				break;
			end
		end

		for a=#self.Spectators, 1, -1 do
			if self.Spectators[a].Player == player then
				table.remove(self.Spectators, a);
				break;
			end
		end
		
	end

	self:Changed(true);
end

function Lobby:Clean()
	local r = modGlobalVars.CloneTable(self);
	
	r.CardPool = nil;
	r.BroadcastQueue = nil;
	r.CardSwapSelections = nil;
	r.StageQueue = nil;
	
	return r;
end

function Lobby:Changed(sync)
	if self.Destroyed then return end;
	
	if sync then
		self.CanStart = (#self.Players > 1 and self.State == GameState.Idle);
		
		local syncPacket = {Lobby=self:Clean();};
		for a=#self.Players, 1, -1 do
			local playerTable = self.Players[a];

			task.spawn(function()
				if playerTable.Player then
					local profile = shared.modProfile:Get(playerTable.Player);
					
					if profile and playerTable.Cards then
						if profile.EquippedTools.ID == nil then
							if #playerTable.Cards > 0 then
								shared.EquipmentSystem.ToolHandler(playerTable.Player, "equip", {MockEquip=true; ItemId="fotlcardgame"});
							end
							
						elseif profile.EquippedTools.StorageItem and profile.EquippedTools.StorageItem.ItemId == "fotlcardgame" then
							if #playerTable.Cards <= 0 then
								shared.EquipmentSystem.ToolHandler(playerTable.Player, "unequip");
							end
						end
					end
				end
			end)
			
			task.spawn(function()
				remoteCardGame:InvokeClient(playerTable.Player, "sync", syncPacket);
			end)

			task.spawn(function()
				local character = playerTable.Player and playerTable.Player.Character;
				if character then
					local foltcardgamePrefab = character:FindFirstChild("fotlcardgame");
					if foltcardgamePrefab and playerTable.Cards then
						foltcardgamePrefab.CardR.Transparency = (self.State == GameState.Active and #playerTable.Cards <= 1) and 1 or 0;
						foltcardgamePrefab.CardL.Transparency = (self.State == GameState.Active and #playerTable.Cards <= 0) and 1 or 0;
					end
				end
			end)
			
		end
		for a=#self.Spectators, 1, -1 do
			task.spawn(function()
				remoteCardGame:InvokeClient(self.Spectators[a].Player, "sync", syncPacket);
			end)
		end
	end
end

--==
function CardGame.LoadLobby(data)
	setmetatable(data, Lobby);
	return data;
end

function CardGame.NewLobby(player)
	local lobby = Lobby.new();
	
	lobby.Host = player;
	lobby:Join(player);
	lobby:SetPlayerType(player, "Players");
	
	Debugger:Log("New lobby ", lobby);
	shared.Notify(player, "[FotL] New lobby created for Fall of the Living.", "Inform");
	
	table.insert(CardGame.Lobbies, lobby);
	
	lobby:Changed(true);
	
	return lobby;
end

function CardGame.GetLobby(player)
	if player == nil or not player:IsDescendantOf(game.Players) then return end;
	
	local lobby;
	for a=#CardGame.Lobbies, 1, -1 do
		if CardGame.Lobbies[a].Destroyed then continue end;
		
		if CardGame.Lobbies[a]:GetPlayer(player) then
			lobby = CardGame.Lobbies[a];
			break;
		end
	end
	
	return lobby;
end

function CardGame.GetPlayerFromInteractable(interactableModule)
	for _, player in pairs(game.Players:GetPlayers()) do
		if player and player.Character and interactableModule:IsDescendantOf(player.Character) then
			return player;
		end
	end
end

if RunService:IsServer() then
	function remoteCardGame.OnServerInvoke(player, action, packet)
		local rPacket = {};
		if remoteCardGame:Debounce(player) then return rPacket end;
		if action == nil then return rPacket end;
		local unixTime = DateTime.now().UnixTimestampMillis;
		
		packet = packet or {};

		Debugger:Log("remoteCardGame", action, packet);
		
		if action == "request" then
			local playerLobby = CardGame.GetLobby(player);
			if playerLobby then
				
				Debugger:Warn("Already in a lobby;");
				return rPacket;
			end
			
			
			local interactableModule = packet.Interactable;

			local hostPlayer = CardGame.GetPlayerFromInteractable(interactableModule);
			local hostLobby = CardGame.GetLobby(hostPlayer);
			if hostLobby == nil then Debugger:Warn("Host does not have a lobby", hostPlayer) return rPacket end;
			
			
			if hostLobby.State == GameState.Idle then
				rPacket.CanQueue = true;
				
			else
				rPacket.CanSpectate = true;
				
			end
			
			
		elseif action == "requestjoin" then
			local interactableModule = packet.Interactable;

			local playerLobby = CardGame.GetLobby(player);
			if playerLobby and playerLobby.Host == player then
				
				shared.Notify(player, "[FotL] You are currently hosting a lobby, leave current lobby in order to join another.", "Negative");
				return rPacket;
			end
			
			local hostPlayer = CardGame.GetPlayerFromInteractable(interactableModule);
			local hostLobby = CardGame.GetLobby(hostPlayer);
			if hostLobby == nil then Debugger:Warn("Host does not have a lobby") return rPacket end;
			
			hostLobby:Join(player);
			shared.Notify(player, "[FotL] Join request sent to ".. hostPlayer.Name ..".", "Inform");
			
		elseif action == "acceptrequest" then
			local acceptPlayer = packet.AcceptPlayer;

			local hostLobby = CardGame.GetLobby(player);
			if hostLobby == nil or hostLobby.Host ~= player then Debugger:Warn("Invalid host request", hostLobby) return rPacket end;
			
			if #hostLobby.Players < 4 then
				hostLobby:SetPlayerType(acceptPlayer, "Players");
				rPacket.Success = true;
				
			else
				shared.Notify(acceptPlayer, "[FotL] The lobby is full!", "Inform");
				shared.Notify(player, "[FotL] The lobby is full!", "Inform");
				
			end

		elseif action == "leave" then
			local lobby = CardGame.GetLobby(player);
			if lobby then
				lobby:Leave(player);
			end
			

		elseif action == "startgame" then
			local lobby = CardGame.GetLobby(player);
			
			if lobby == nil or lobby.Host ~= player then
				Debugger:Warn("Not lobby host", lobby);
				return rPacket;
			end
			
			Debugger:Log("lobby", lobby);
			if #lobby.Players > 5 then
				shared.Notify(player, "[FotL] The lobby is overloaded!", "Inform");
				return rPacket;
			end
			if #lobby.Players < 2 then
				shared.Notify(player, "[FotL] Needs more players", "Inform");
				return rPacket;
			end
			
			lobby:Start();
			
			
		elseif action == "playaction" then
			local lobby = CardGame.GetLobby(player);
			
			if lobby == nil or lobby.StageIndex ~= packet.StageIndex then Debugger:Log("false lobby", lobby); return rPacket end;
			local playerTable = lobby.Players[lobby.TurnIndex];
			
			if playerTable.Player ~= player then Debugger:Log("false player", playerTable); return rPacket; end
			if packet.OptionIndex == nil then Debugger:Log("false OptionIndex", packet); return rPacket; end

			local stageInfo = lobby.StageQueue[lobby.StageIndex];
			if stageInfo == nil then Debugger:Log("false StageQueue", packet); return rPacket; end
			if stageInfo.Type ~= StageType.NextTurn then Debugger:Log("false stageInfo", packet); return rPacket; end
			
			local optionLib = CardGame.ActionOptions[packet.OptionIndex];
			
			if optionLib.SelectTarget then
				local targetLobby = CardGame.GetLobby(packet.TargetPlayer);
				if targetLobby ~= lobby then Debugger:Log("false TargetPlayer lobby", packet); return rPacket end;
				if targetLobby:GetPlayer(packet.TargetPlayer).Type == "Spectators" then Debugger:Log("false TargetPlayer type", targetLobby); return rPacket end;
				if packet.TargetPlayer == player then Debugger:Log("false TargetPlayer", packet); return rPacket end;
			end
			
			lobby:PlayAction(player, packet);

		elseif action == "pickcards" then
			local lobby = CardGame.GetLobby(player);

			if lobby == nil or lobby.StageIndex ~= packet.StageIndex then Debugger:Log("false lobby", lobby); return rPacket end;

			local playerTable = lobby:GetPlayer(player);
			
			local stageInfo = lobby.StageQueue[lobby.StageIndex];
			if playerTable.Player ~= stageInfo.TurnPlayer then Debugger:Log("false player", stageInfo); return rPacket; end
			
			if packet.PickedCards then
				--== Picked cards;
				if lobby.CardSwapSelections == nil then Debugger:Log("false CardSwapSelections", lobby); return rPacket end;
				
				packet.OptionIndex = 7;
				lobby:PlayAction(player, packet);
				rPacket.NewCards = playerTable.Cards;
				
			else
				--== Pick cards start;

				if packet.OptionIndex == nil then Debugger:Log("false OptionIndex", packet); return rPacket; end

				local optionLib = CardGame.ActionOptions[packet.OptionIndex];
				if optionLib.PickCards ~= true then Debugger:Log("false PickCards", lobby); return rPacket end;

				lobby:PlayAction(player, packet);
				rPacket.PickedCards = lobby.CardSwapSelections;
				
				
			end

		elseif action == "decideaction" then
			local lobby = CardGame.GetLobby(player);

			if lobby == nil or lobby.StageIndex ~= packet.StageIndex then Debugger:Log("false lobby", lobby); return rPacket end;
			
			local stageInfo = lobby.StageQueue[lobby.StageIndex];
			if stageInfo.TargettedPlayer ~= nil and stageInfo.TargettedPlayer ~= player then Debugger:Log("false player", stageInfo); return rPacket; end
			
			local playerTable = lobby:GetPlayer(player);

			if packet.CallBluff == true then
				Debugger:Log("decideaction stageInfo", stageInfo);
				--local optionLib = CardGame.ActionOptions[stageInfo.ActionId];
				--if stageInfo.AttackDispute == nil and optionLib and optionLib.Requires == nil then Debugger:Log("false optionLib", stageInfo); return rPacket; end
				
				if stageInfo.BluffCalled then Debugger:Log("bluff already called", stageInfo); return rPacket; end
				stageInfo.BluffCalled = true;
				
				stageInfo.Accuser=player;
				stageInfo.Defendant=stageInfo.Victim or stageInfo.TurnPlayer;
				
				lobby:QueueStage(StageType.BluffTrial, stageInfo);
				if stageInfo.ActionId ~= 7 then
					lobby:NextTurn();
				end
				
			else
				if stageInfo.ActionId == 3 then
					lobby:PlayAction(player, packet);
					
				end
				
			end
			

		elseif action == "fold" then
			local lobby = CardGame.GetLobby(player);

			if lobby == nil or lobby.StageIndex ~= packet.StageIndex then Debugger:Log("false lobby", lobby); return rPacket end;
			local stageInfo = lobby.StageQueue[lobby.StageIndex];
			
			if stageInfo.Loser ~= player then Debugger:Log("false loser", stageInfo); return rPacket; end
			local loserPlayerTable = lobby:GetPlayer(player);
			
			lobby:PlayAction(player, packet);
			rPacket.NewCards = loserPlayerTable.Cards;
			
			
		elseif action == "attackdispute" then
			local lobby = CardGame.GetLobby(player);

			if lobby == nil or lobby.StageIndex ~= packet.StageIndex then Debugger:Log("false lobby", lobby); return rPacket end;
			local stageInfo = lobby.StageQueue[lobby.StageIndex];
			
			packet.AttackDisputeChoice = packet.AttackDisputeChoice == 2 and 2 or 1;
			
			lobby:PlayAction(player, packet)
			
			
		elseif action == "newmatch" then

			CardGame.NewLobby(player);
			local lobby = CardGame.GetLobby(player);
			lobby:Changed(true);
			
		end
		
		return rPacket;
	end
	
end

Debugger:Log("Initialized CardGame");
return CardGame;