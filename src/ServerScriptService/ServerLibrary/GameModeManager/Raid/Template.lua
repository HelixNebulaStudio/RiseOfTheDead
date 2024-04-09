local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local GameController = {};
local enumGameStatus = {Restarting=0; InProgress=1; Completed=2;};

local TweenService = game:GetService("TweenService");

local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);
local modGameModeManager = require(game.ServerScriptService.ServerLibrary.GameModeManager);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modClothing = require(game.ServerScriptService.ServerLibrary.Clothing);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modCrates = require(game.ServerScriptService.ServerLibrary.Crates);
local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);
local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local remotes = game.ReplicatedStorage.Remotes;
local bindOnDoorEnter = remotes.Interactable.OnDoorEnter;
local remoteGameModeHud = modRemotesManager:Get("GameModeHud");

local environment = workspace:WaitForChild("Environment");

local spawnRandom = Random.new();
local levelRandom = Random.new();
local waitForDoorOpen = true;

GameController.Characters = {};
GameController.Enemies = {};
GameController.Status = enumGameStatus.InProgress;
GameController.TimesFailed = 0;

local gameType, stageType = script.Parent.Name, script.Name;

local GameLib = modGameModeLibrary.GetGameMode(gameType);
local StageLib = GameLib and modGameModeLibrary.GetStage(gameType, script.Name);

local Stages = {
	{ -- Stage 1
		Spawns={};
		Duration=20;
		Enemies={
			{Name="Zombie"; Chance=1};
		};
		UnlockDoors={"StageDoor1"};
	};
	{ -- Stage 2
		Spawns={};
		Duration=10;
		Enemies={
			{Name="Zombie"; Chance=0.8};
			{Name="Ticks Zombie"; Chance=0.2};
		};
		UnlockDoors={"StageDoor2"};
	};
	{ -- Stage 3
		Spawns={};
		Duration=30;
		Enemies={
			{Name="Zombie"; Chance=0.6};
			{Name="Ticks Zombie"; Chance=0.2};
			{Name="Leaper Zombie"; Chance=0.2};
		};
		UnlockDoors={"StageDoor3"};
	};
	{ -- Stage 4
		UsePrevStageSpawns = false;
		Spawns={};
		Duration=10;
		Enemies={
			{Name="Zombie"; Chance=0.5};
			{Name="Ticks Zombie"; Chance=0.2};
			{Name="Leaper Zombie"; Chance=0.3};
		};
		UnlockDoors={"Floor1EntranceDoor"; "StageDoor4"; "Floor1ExitDoor"};
	};
	{ -- Stage 5
		Spawns={};
		Duration=15;
		Enemies={
			{Name="Zombie"; Chance=0.5};
			{Name="Ticks Zombie"; Chance=0.2};
			{Name="Leaper Zombie"; Chance=0.3};
		};
		UnlockDoors={"StageDoor5"};
	};
	{ -- Stage 6
		Spawns={};
		Duration=60;
		Enemies={
			{Name="Zombie"; Chance=0.8};
			{Name="Ticks Zombie"; Chance=0.2};
			{Name="Leaper Zombie"; Chance=0.2};
			{Name="Heavy Zombie"; Chance=0.1};
		};
		UnlockDoors={"StageDoor6"};
	};
}
--== Script;

function GameController:Hud(data)
	remoteGameModeHud:FireAllClients({
		Action="Open";
		Type=gameType;
		Stage=stageType;
		Header=data.Header or gameType..": "..stageType;
		Status=data.Status;
		PlayMusic=data.PlayMusic;
		NextStageSound=data.NextStageSound;
	});
end

function GameController:StartStage(stage)
	local stageInfo = Stages[stage];
	
	if stage >= 7 then
		GameController:Hud({
			Header="Raid Complete";
			Status="Head to the exit";
		})
		
		
		for a=#self.Players, 1, -1 do
			if not self.Players[a]:IsDescendantOf(game.Players) then
				table.remove(self.Players, a);
				
			end
		end
		
		GameController:RespawnDead();
		
		local rewardSpawn = environment.StageElements:WaitForChild("RewardSpawn");
		modItemDrops.Spawn({Type="Crate"; ItemId=StageLib.RewardsId}, CFrame.new(rewardSpawn.Position), self.Players, false);
		GameController.Status = enumGameStatus.Completed;
		workspace:SetAttribute("GameModeComplete", true);
		
		for a=1, #self.Players do
			modStatusEffects.FullHeal(self.Players[a]);
		end
		if GameController.OnComplete then
			GameController.OnComplete(game.Players:GetPlayers());
		end
		GameController:ToggleDoor(nil, true, true);
		
		return;
	end
	
	if stageInfo.UnlockDoors then
		for a=1, #stageInfo.UnlockDoors do
			GameController:ToggleDoor(stageInfo.UnlockDoors[a], true);
			waitForDoorOpen = true;
		end
	end
	if stageInfo.LockDoors then
		for a=1, #stageInfo.LockDoors do
			GameController:ToggleDoor(stageInfo.LockDoors[a], false);
		end
	end

	modInteractables:SyncAll();
	
	local stageSound = true;
	repeat
		GameController:Hud({
			Header="Stage "..stage;
			Status="Enter the next stage";
			NextStageSound=stageSound;
		})
		stageSound=false;
		wait(1); 
	until not waitForDoorOpen or GameController.Status ~= enumGameStatus.InProgress;
	if GameController.Status ~= enumGameStatus.InProgress then return end;
	
	if stage == 1 then
		GameController:Hud({
			PlayMusic=true;
		})
	end
	
	GameController:Hud({
		Header="Stage "..stage;
		Status="Clear out the enemies";
	})
	
	local function spawnEnemy(enemyName, spawnPoint)
		modNpc.Spawn(enemyName, spawnPoint, function(npc, npcModule)
			table.insert(GameController.Enemies, npcModule);
			npcModule.Configuration.Level = npcModule.Configuration.Level + GameController.Difficulty + levelRandom:NextInteger(-1, 1);
			npcModule.ForgetEnemies = false;
			npcModule.AutoSearch = true;
			npcModule.Properties.TargetableDistance = 4096;
			npcModule.OnTarget(self.Players);
			
			npcModule.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject;
			npcModule.Humanoid.Health = npcModule.Humanoid.MaxHealth;
			
			local isAlive = true;
			npcModule.Humanoid.Died:Connect(function()
				isAlive = false;
				for a=#GameController.Enemies, 1, -1 do
					if GameController.Enemies[a] == npcModule then
						table.remove(GameController.Enemies, a);
					end
				end
				npcModule.DeathPosition = npcModule.RootPart.CFrame.p;
			end);
			
			spawn(function()
				while true do
					wait(120);
					if not isAlive then return; end;
					if npcModule.RootPart then
						npcModule.RootPart.CFrame = spawnPoint;
					end
				end	
			end)
		end);
	end
	
	local function pickSpawn()
		local spawns = {};
		if stage > 1 and stageInfo.UsePrevStageSpawns ~= false then
			local prevStage = stage-1;
			for a=1, #Stages[prevStage].Spawns do
				table.insert(spawns, Stages[prevStage].Spawns[a]);
			end
		end
		for a=1, #stageInfo.Spawns do
			table.insert(spawns, stageInfo.Spawns[a]);
		end
		return spawns[math.random(1, #spawns)].CFrame;
	end
	
	local pickTable = {};
	local totalChance = 0;
	for a=1, #stageInfo.Enemies do
		local data = stageInfo.Enemies[a];
		totalChance = totalChance + data.Chance;
		table.insert(pickTable, {Total=totalChance; Data=stageInfo.Enemies[a]});
	end
	
	local function pickEnemy()
		local roll = spawnRandom:NextNumber(0, totalChance);
		for a=1, #pickTable do
			if roll <= pickTable[a].Total then
				return pickTable[a].Data.Name;
			end
		end
		return "Zombie";
	end
	
	Debugger:Log(stage,"started.")
	local spawnChance = 1;
	local stageTick = tick();
	repeat
		if math.random(1, 100)/100 <= spawnChance then
			spawnEnemy(pickEnemy(), pickSpawn());
		end
		
		if #GameController.Enemies > 100 then
			spawnChance = 0;
		elseif #GameController.Enemies > 50 then
			spawnChance = 0.1;
		elseif #GameController.Enemies > 35 then
			spawnChance = 0.4;
		elseif #GameController.Enemies > 25 then
			spawnChance = 0.45;
		elseif #GameController.Enemies > 15 then
			spawnChance = 0.5;
		end
		
		if spawnChance ~= 1 then
			spawnChance = spawnChance/math.clamp(GameController.TimesFailed, 1, 10);
		end
		wait(1);
	until tick()-stageTick >= stageInfo.Duration or self.Status ~= enumGameStatus.InProgress;
	repeat wait(0.5) until #GameController.Enemies <= 0;
	Debugger:Log(stage,"complete.")
	
	if self.Status == enumGameStatus.InProgress then
		GameController.Stage = GameController.Stage +1;
		GameController:StartStage(GameController.Stage);
	end
end

function GameController:RespawnDead()
	for _, player in pairs(self.Players) do
		if player and player:IsDescendantOf(game.Players) then
			local classPlayer = shared.modPlayers.Get(player);
			if not classPlayer.IsAlive then
				classPlayer:Spawn();
			end
		end
	end
end

function GameController:Start()
	GameController.Status = enumGameStatus.InProgress;
	GameController.Stage = 1;
	GameController.Difficulty = 1;
	
	remoteGameModeHud:FireAllClients({
		Action="Open";
		Type=gameType;
		Stage=stageType;
	});
	
	local highestLevel = 0;
	for _, player in pairs(self.Players) do
		local playerProfile = modProfile:Get(player);
		if playerProfile then
			local playerSave = playerProfile:GetActiveSave();
			local playerLevel = playerSave and playerSave:GetStat("Level") or 1;
			local focusLevel = modGlobalVars.GetLevelToFocus(playerLevel);
			if focusLevel > highestLevel then
				highestLevel = focusLevel;
			end
		end
		modStatusEffects.FullHeal(player);
	end
	
	GameController.Difficulty = math.clamp(highestLevel, 1, math.huge);
	Debugger:Log("Game started with difficulty,", GameController.Difficulty);
	
	for a=1, #Stages do
		if Stages[a].UnlockDoors then
			for b=1, #Stages[a].UnlockDoors do
				GameController:ToggleDoor(Stages[a].UnlockDoors[b], false, true);
			end
		end
		if Stages[a].LockDoors then
			for b=1, #Stages[a].LockDoors do
				GameController:ToggleDoor(Stages[a].LockDoors[b], false, true);
			end
		end
	end
	
	for _, obj in pairs(workspace.Interactables:GetChildren()) do
		if obj.Name == "gameExit" then
			local interactGameExit = require(obj:WaitForChild("Interactable"));
			interactGameExit.Script = obj.Interactable;
			interactGameExit.UnlockTime = os.time();
			interactGameExit.Enabled = true;
			interactGameExit:Sync();
		end
	end
	
	GameController:RespawnDead();
	for a=1, 20, 0.5 do
		GameController:Hud({
			Status="Waiting for ("..#GameController.Characters.."/"..#self.Players..") characters.."
		})
		if #GameController.Characters >= #self.Players then
			break;
		else
			wait(0.5);
		end
	end
	
	for a=5, 1, -1 do
		GameController:Hud({
			Status="Raid is starting in "..a.."s.."
		})
		wait(1);
	end
	
	GameController:StartStage(GameController.Stage);
end

function OnCharacterAdded(character)
	for a=#GameController.Characters, 1, -1 do
		if GameController.Characters[a].Name == character.Name then
			table.remove(GameController.Characters, a);
		end
	end
	table.insert(GameController.Characters, character);
	
	local player = game.Players[character.Name];
	local humanoid = character:WaitForChild("Humanoid");
	local classPlayer = shared.modPlayers.Get(player);
	classPlayer:OnNotIsAlive(function(character)
		Debugger:Log(character.Name,"died");
		shared.Notify(game.Players:GetPlayers(), ("$name died!"):gsub("$name", character.Name), "Negative");
		for a=#GameController.Characters, 0, -1 do
			if GameController.Characters[a] == character then
				table.remove(GameController.Characters, a);
			end
		end
		Debugger:Log("Players alive",#GameController.Characters);
		
		if #GameController.Characters <= 0 and GameController.Status == enumGameStatus.InProgress then
			
			if GameController.TimesFailed+1 > 5 then
				GameController:Hud({
					Header="Raid failed!";
					Status="Leaving Raid..";
					PlayMusic=false;
				});
				
				for _, player in pairs(game.Players:GetPlayers()) do
					modGameModeManager:ExitGamemodeWorld(player);
				end
				return;
			end
			
			GameController:Hud({
				Header="Raid failed!";
				Status="Restarting..";
				PlayMusic=false;
			})
			GameController.Status = enumGameStatus.Restarting;
			for a=#GameController.Enemies, 1, -1 do
				game.Debris:AddItem(GameController.Enemies[a].Prefab, 0);
				table.remove(GameController.Enemies, a);
			end
			GameController.TimesFailed = GameController.TimesFailed +1;
			
			wait(5);
			GameController:Start();
		else
			remoteGameModeHud:FireClient(player, {
				Header="You died!";
				Status="Spectating";
			});
			
		end
		if GameController.Status == enumGameStatus.Completed then
			local player = game.Players:GetPlayerFromCharacter(character);
			if player then
				wait(1);
				local classPlayer = shared.modPlayers.Get(player);
				classPlayer:Spawn();
			end
		end
	end)
end

function GameController:Initialize(roomData)
	self.RoomData = roomData;
	self.Players = {};
	
	for a=1, #roomData.Players do
		spawn(function()
			while true do
				local player = game.Players:FindFirstChild(roomData.Players[a].Name);
				if player then
					player.CharacterAdded:Connect(OnCharacterAdded);
					local classPlayer = shared.modPlayers.Get(player);
					classPlayer:Spawn();
					table.insert(self.Players, player);
					break;
				end
				wait(1);
			end
		end)
	end
	
	game.Players.PlayerRemoving:Connect(function(player)
		for a=#self.Players, 1, -1 do
			if not self.Players[a]:IsDescendantOf(game.Players) then
				table.remove(self.Players, a);
			end
		end
	end)
	
	for a=1, 20, 0.5 do
		shared.Notify(game.Players:GetPlayers(), "Waiting for ("..#self.Players.."/"..#roomData.Players..") players..", "Inform", "WaitingForPlayer");
	
		if #self.Players >= #roomData.Players then
			break;
		else
			wait(0.5);
		end
	end
	
	-- Load spawns
	local stageElements = environment:WaitForChild("StageElements");
	for stage=1, #Stages do
		for _, obj in pairs(stageElements:WaitForChild("Spawns"):GetChildren()) do
			if obj.Name == "Stage"..stage then
				table.insert(Stages[stage].Spawns, obj);
				obj.Transparency = 1;
			end
		end
	end

	modInteractables:SyncAll();
	GameController:Start();
end

return GameController;