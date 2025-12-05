local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local bossAnnouncements = {
	"Who is provoking $bossName!";
	"$bossName is being awoken!";
	"Who dares disturb $bossName!";
	"$bossName is being summoned!";
	"$bossName is riled up!"
}

--==
local RunService = game:GetService("RunService");

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);

local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);

local modNpcs = shared.modNpcs;
local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
local modAnalytics = shared.require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modProfile = shared.require(game.ServerScriptService.ServerLibrary.Profile);

local remoteGameModeUpdate = modRemotesManager:Get("GameModeUpdate");
local remoteGameModeHud = modRemotesManager:Get("GameModeHud");
--==
local GameMode = {};
GameMode.__index = GameMode;

function GameMode:Init(gameTable)
	self.GameTable = gameTable;
end

function GameMode:AnnounceReady()
	shared.Notify(
		game.Players:GetPlayers(), 
		(bossAnnouncements[math.random(1, #bossAnnouncements)]):gsub("$bossName", self.GameTable.Stage),
		"Defeated");
end

function GameMode:Load(room)
	local bossArena = room.LobbyPrefab;
	
	local arenaInteractables = bossArena:WaitForChild("Interactables") and bossArena.Interactables:GetChildren();
	
	for a=1, #arenaInteractables do
		if arenaInteractables[a]:IsA("BasePart") then
			arenaInteractables[a].Parent = workspace.Interactables;
			arenaInteractables[a].Transparency = 1;
			
			table.insert(room.Prefabs, arenaInteractables[a]);
			if arenaInteractables[a].Name == "ExitDoor" then
				room.ExitDoor = arenaInteractables[a];
				
			elseif arenaInteractables[a].Name == "neonSign" then
				room.NeonSign = arenaInteractables[a]:FindFirstChild("ExitSign", true);
			end
		end
	end
	
	local arenaClips = bossArena:FindFirstChild("Clips") and bossArena.Clips:GetChildren();
	if arenaClips then
		for _, obj in pairs(arenaClips) do
			if obj:IsA("BasePart") then
				obj.Transparency = 1;
			end
		end
	end

	local roomMeta = getmetatable(room);
	
	if bossArena:FindFirstChild("BossArena") then
		roomMeta.ArenaModule = shared.require(bossArena.BossArena);
		
		if roomMeta.ArenaModule.Load then
			task.spawn(function()
				room.ArenaModule:Load();
			end)
		end
	end
end

function GameMode:Start(room)
	local roomMeta = getmetatable(room);
	
	local bossLib = self.GameTable.StageLib;
	
	local died = false;
					
	local bossArena = room.LobbyPrefab;
	local bossSpawnObject = bossArena:WaitForChild("BossSpawn");
	local newSpawnPoint = modNpcs.GetCFrameFromPlatform(bossSpawnObject);
	
	local players = room:GetInstancePlayers();

	local highestFocusLevel = 0;
	for _, player in pairs(players) do
		local playerProfile = modProfile:Get(player);
		if playerProfile then
			local playerSave = playerProfile:GetActiveSave();
			local playerLevel = playerSave and playerSave:GetStat("Level") or 1;
			local focusLevel = modGlobalVars.GetLevelToFocus(playerLevel);
			if focusLevel > highestFocusLevel then
				highestFocusLevel = focusLevel;
			end
		end
	end
	for _, player in pairs(players) do
		local mission = modMission:GetMission(player, 7);
		if mission == nil or mission.ProgressionPoint <= 4 then
			highestFocusLevel = 1;
		end
	end

	local bossLevel = math.clamp(highestFocusLevel, 1, math.huge);
	Debugger:Warn("Boss started with level:", bossLevel);
		
	for a=1, #players do
		local classPlayer = modPlayers.get(players[a]);
		classPlayer:SetProperties("InBossBattle", self.GameTable.Stage);
		
		remoteGameModeUpdate:FireClient(players[a], "closemenu");
		remoteGameModeHud:FireClient(players[a], {
			Action="Open";
			Type="Boss";
			Stage=self.GameTable.Stage;
			Room=room;
		});
	end
	room.BossPrefabs = {};
	
	task.wait(3);
	if room.State ~= modGameModeLibrary.RoomStatesEnums.InProgress then return end;
	
	local arenaTimer = tick();
	
	local function npcSpawnSetup(bossNpcClass: NpcClass)
		local bossCharacter = bossNpcClass.Character;

		table.insert(room.BossPrefabs, bossCharacter);
		table.insert(room.Prefabs, bossCharacter);
		bossCharacter:SetAttribute("EntityHudHealth", true);

		bossNpcClass.NetworkOwners = players;

		local properties = bossNpcClass.Properties;
		properties.Level = math.max(bossLevel, 1);

		properties.Arena = bossArena;
		properties.HardMode = room.IsHard;
		properties.CrateId = bossLib.CrateId;
		properties.TargetableDistance = 4096;
		
		roomMeta.BossNpcModules = {};
		table.insert(roomMeta.BossNpcModules, bossNpcClass);

		for _, player in pairs(players) do
			bossCharacter:AddPersistentPlayer(player);

			local playerClass: PlayerClass = modPlayers.get(player);
			if playerClass and playerClass.Humanoid then
				bossNpcClass.Garbage:Tag(playerClass.Humanoid.Died:Connect(function()
					if bossNpcClass.NetworkOwners == nil then
						return;
					end
					for a=#bossNpcClass.NetworkOwners, 1, -1 do
						if bossNpcClass.NetworkOwners[a] == player then
							table.remove(bossNpcClass.NetworkOwners, a);
						end
					end
				end));
			end
			
			local playerNpcsList = modNpcs.listNpcClasses(function(npcClass: NpcClass)
				return npcClass.Player == player;
			end)
			if playerNpcsList then
				for a=1, #playerNpcsList do
					local playerNpcClass: NpcClass = playerNpcsList[a];
					if playerNpcClass.Properties.FollowingPlayer ~= player then
						continue;
					end

					local targetHandlerComp = playerNpcClass:GetComponent("TargetHandler");
					if targetHandlerComp then
						targetHandlerComp:AddTarget(bossNpcClass.Character, bossNpcClass.HealthComp)
					else
						playerNpcsList[a].Target = bossCharacter; -- MARK: Using deprecated .Target field
					end
				end
			end
		end

		local healthComp: HealthComp = bossNpcClass.HealthComp;
		healthComp.OnIsDeadChanged:Connect(function()
			Debugger:Warn("Boss defeated");
			local deathPos = bossNpcClass.RootPart.Position;

			for a=#room.BossPrefabs, 1, -1 do
				if room.BossPrefabs[a] == bossCharacter then
					table.remove(room.BossPrefabs, a);
				end
			end

			players = room:GetInstancePlayers();
			for _, player in pairs(players) do
				shared.Notify(player, bossNpcClass.Name, "BossDefeat");
			end
			shared.modEventService:ServerInvoke("Boss_BindDefeated", {ReplicateTo=players}, {
				NpcClass = bossNpcClass;
			});

			if room.State == modGameModeLibrary.RoomStatesEnums.InProgress and #room.BossPrefabs <= 0 then
				room:SetState(modGameModeLibrary.RoomStatesEnums.Ending);
				
				if died then return end;
				died = true;
				
				task.spawn(function()
					local crateRewardComp = bossNpcClass:GetComponent("CrateReward");
					if crateRewardComp == nil then
						crateRewardComp = bossNpcClass:AddComponent("CrateReward");
					end
					if crateRewardComp then
						local crateSpawnPos = bossArena.PrimaryPart:FindFirstChild("CrateSpawn") and bossArena.PrimaryPart.CrateSpawn.WorldPosition;
						local spawnCFrame = crateSpawnPos and CFrame.new(crateSpawnPos) or nil;
						if crateSpawnPos == nil then
							local _dropRayHit, dropRayPos = workspace:FindPartOnRayWithWhitelist(
								Ray.new(deathPos, Vector3.new(0, -32, 0)), 
								{workspace.Environment; workspace.Terrain}, 
								true
							);
							spawnCFrame = CFrame.new(dropRayPos);
						end
						spawnCFrame = spawnCFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);

						local cratePrefab = crateRewardComp(spawnCFrame, players);
						Debugger.Expire(cratePrefab, 15);
					else
						Debugger:Warn(`Missing CrateReward component for {bossNpcClass.Name}`);
					end
					
					for _, player in pairs(players) do
						modAnalytics.RecordProgression(player.UserId, "Complete", "Boss:"..(room.IsHard and "Hard-" or "")..self.GameTable.Stage);
						
						local profile = modProfile:Get(player);
						local timePlayed = math.ceil(tick()-arenaTimer);
						profile.Analytics:LogTime("Arena:"..(room.IsHard and "Hard-" or "")..self.GameTable.Stage, timePlayed);
					end
				end)
			end

		end)
	end

	for npcName, _ in pairs(bossLib.Prefabs) do
		newSpawnPoint = modNpcs.GetCFrameFromPlatform(bossSpawnObject);
		
		modNpcs.spawn2{
			Name = npcName;
			CFrame = newSpawnPoint;

			AddComponents = {"CrateReward"};
			BindSetup = npcSpawnSetup;
		};
	end
	
	task.spawn(function()
		task.wait(0.5);
		for i=1, 3 do
			for a=1, #players do
				remoteGameModeHud:FireClient(players[a], {
					Action="Open";
					Type="Boss";
					Stage=self.GameTable.Stage;
					Room=room;
				});
			end
			task.wait(1);
		end
	end)
	
	task.spawn(function()
		local arenaCFrame = bossArena:GetPrimaryPartCFrame();
		local arenaSize = arenaCFrame:vectorToWorldSpace(bossArena:GetExtentsSize());
		arenaSize = Vector3.new(math.abs(arenaSize.X), math.abs(arenaSize.Y), math.abs(arenaSize.Z));

		local arenaMin = Vector3.new(arenaCFrame.p.X - arenaSize.X/2, arenaCFrame.p.Y-2, arenaCFrame.p.Z - arenaSize.Z/2);
		local arenaMax = Vector3.new(arenaCFrame.p.X + arenaSize.X/2, arenaCFrame.p.Y + arenaSize.Y, arenaCFrame.p.Z + arenaSize.Z/2);
		
		while room.State == modGameModeLibrary.RoomStatesEnums.InProgress and #room.Players > 0 do
			if bossLib.NoArenaBoundaries ~= true then
				room:ForEachPlayer(function(playerData)
					local player: Player = playerData.Instance;
					local playerClass: PlayerClass = modPlayers.get(player);
					local rootPart = playerClass.RootPart;
					if rootPart then
						if rootPart.CFrame.p.X <= arenaMin.X
						or rootPart.CFrame.p.Y <= arenaMin.Y
						or rootPart.CFrame.p.Z <= arenaMin.Z
						or rootPart.CFrame.p.X >= arenaMax.X
						or rootPart.CFrame.p.Y >= arenaMax.Y
							or rootPart.CFrame.p.Z >= arenaMax.Z then
							
							playerClass:SetCFrame(newSpawnPoint); --Teleport back into arena;
						end
					end
				end);
			end
			
			-- clear overtime lobbies.
			if room.StartTime and modSyncTime.GetTime() - room.StartTime >= 600 then
				shared.Notify(room:GetInstancePlayers(), "Times up! You could not defeat "..self.GameTable.Stage.." in time.", "Negative");
				room:SetState(modGameModeLibrary.RoomStatesEnums.Ending);
			end

			task.wait(0.5);
		end
		room.OnPlayersChanged:Fire();
	end)
	
	if bossArena:FindFirstChild("BossArena") then
		roomMeta.ArenaModule = shared.require(bossArena.BossArena);
	end
	if room.ArenaModule and room.ArenaModule.SetRoom then
		room.ArenaModule:SetRoom(room);
	end
	if room.ArenaModule and room.ArenaModule.Start then
		task.spawn(function()
			room.ArenaModule:Start();
		end)
	end
end

function GameMode:End(room)
	if room.BossPrefabs then
		for a=#room.BossPrefabs, 1, -1 do
			if room.BossPrefabs[a] then
				--room.BossPrefabs[a]:Destroy();
				table.remove(room.BossPrefabs, a);
			end
		end
	end
	local players = room:GetInstancePlayers();
	
	for a=1, #players do
		local classPlayer = modPlayers.get(players[a]);
		classPlayer:SetProperties("InBossBattle", nil);
		
		remoteGameModeHud:FireClient(players[a], {
			Action="Open";
			Type="Boss";
			Stage=self.GameTable.Stage;
			EndTime=room.EndTime;
			Room=room;
		});
	end
	
	if room.ExitDoor then
		local remoteExit = Instance.new("RemoteFunction");
		remoteExit.Name = "ExitBossArena";
		remoteExit.Parent = room.ExitDoor;
		
		function remoteExit.OnServerInvoke(player)
			remoteGameModeHud:FireClient(player, {
				Action="Close";
			});
			self.GameTable:DisconnectPlayer(player);
			room:RemovePlayer(player);
		end
	else
		for a=1, #players do
			self.GameTable:DisconnectPlayer(players[a], false);
			room:RemovePlayer(players[a]);
			remoteGameModeHud:FireClient(players[a], {
				Action="Close";
			});
		end
		
		Debugger:Warn("Arena does not have an exit door!");
	end
	if room.NeonSign then
		room.NeonSign.Material = Enum.Material.Neon;
		room.NeonSign.SpotLight.Enabled = true;
	end
	if room.ArenaModule and room.ArenaModule.End then
		task.spawn(function()
			room.ArenaModule:End();
		end)
	end
end

function GameMode.new(gameTable)
	local self = {};
	
	setmetatable(self, GameMode);
	return self;
end

return GameMode;