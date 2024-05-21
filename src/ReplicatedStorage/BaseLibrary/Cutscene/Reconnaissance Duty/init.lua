local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modEntity = require(game.ReplicatedStorage.Library.Entity);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modGpsLibrary = require(game.ReplicatedStorage.Library.GpsLibrary);

local random = Random.new();
--== Server Variables;
if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	modFactions = require(game.ServerScriptService.ServerLibrary.Factions);
	
	modOnGameEvents:ConnectEvent("OnTrigger", function(triggerPlayer, interactData, packet)
		
		if interactData.TriggerTag == "mission60RepairBanner" then
			local interactObjectFactionTag = interactData.Object.Parent:GetAttribute("FactionTag");
			
			for _, player in pairs(game.Players:GetPlayers()) do
				local profile = shared.modProfile:Get(player);
				if profile == nil then continue end;
				
				local factionTag = tostring(profile.Faction.Tag);
				
				if factionTag == interactObjectFactionTag then
					modMission:Progress(player, 60, function(mission)
						if mission.ProgressionPoint == 1 then
							shared.Notify(player, triggerPlayer.Name .." has repaired the faction banner.", "Reward");
							mission.ProgressionPoint = 2;

							mission.StartTime = os.time();
							mission.Timer = 300;
							
						end
					end)
				end
			end
		end
	end)
	
	bannersFolder = Instance.new("Folder");
	bannersFolder.Name = "BannersFolder";
	bannersFolder.Parent = workspace:WaitForChild("Environment");
end


local cache = {};
--== Script;
return function(CutsceneSequence)
	--if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, 60);
		if mission == nil then return end;

		Debugger:StudioLog("mission.SaveData", mission.SaveData);
		local profile = shared.modProfile:Get(player);
		Debugger:StudioLog("profile.Faction", profile.Faction);

		local factionTag = tostring(profile.Faction.Tag);
		local factionTitle = profile.Faction.FactionTitle;
		local factionIcon = profile.Faction.FactionIcon;
		local factionColor = profile.Faction.FactionColor;
		
		local gpsLib = modGpsLibrary:FindByKeyValue("Name", mission.SaveData.Location);
		
		if not modBranchConfigs.IsWorld(gpsLib.WorldName) then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
		
		local spawnPart = workspace:FindFirstChild(gpsLib.SetSpawn);
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then
					
					for _, obj in pairs(bannersFolder:GetChildren()) do
						if obj.Name == factionTitle then
							game.Debris:AddItem(obj, 0);
						end
					end
					
					local factionbannerPrefab = game.ReplicatedStorage.Prefabs.Items.factionbanner:Clone();
					
					local interactableModule = script.Interactable:Clone();
					interactableModule.Parent = factionbannerPrefab;
					
					local primaryPart = factionbannerPrefab:WaitForChild("Handle");
					primaryPart.Anchored = true;

					Debugger:StudioWarn("factionColor", factionColor);

					local bannerPart = factionbannerPrefab:WaitForChild("banner");
					for _, decal in pairs(bannerPart:GetChildren()) do
						if decal:IsA("Decal") then
							decal.Texture = "rbxassetid://".. factionIcon;
						end
					end
					for _, obj in pairs(factionbannerPrefab:GetChildren()) do
						if obj.Name == "flag" then
							obj.Color = Color3.fromHex(factionColor);
						end
					end
					
					local halfSize = spawnPart.Size/2;
					local pos = spawnPart.Position;
					pos = pos + Vector3.new(math.random(-halfSize.X, halfSize.X), halfSize.Y, math.random(-halfSize.Z, halfSize.Z));
					
					factionbannerPrefab:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0));
					
					factionbannerPrefab.Name = factionTitle;

					factionbannerPrefab:SetAttribute("FactionTag", factionTag);
					factionbannerPrefab.PrimaryPart = factionbannerPrefab:WaitForChild("root");
					factionbannerPrefab.Parent = bannersFolder;
					
					task.delay(300, function()
						local bannerDestructible = modEntity:GetDestructible(factionbannerPrefab);
						if bannerDestructible then
							bannerDestructible.MaxHealth = 10000;
							bannerDestructible.Health = bannerDestructible.MaxHealth;
							bannerDestructible.Enabled = true;
						end
					end)
					
				elseif mission.ProgressionPoint == 2 then
					local factionbannerPrefab = bannersFolder:FindFirstChild(factionTitle);
					if factionbannerPrefab then
						factionbannerPrefab:SetAttribute("Repaired", true);
						
						local bannerDestructible = modEntity:GetDestructible(factionbannerPrefab);
						if bannerDestructible then
							bannerDestructible.MaxHealth = 10000;
							bannerDestructible.Health = bannerDestructible.MaxHealth;
							bannerDestructible.Enabled = true;
						end
					end
					
					--======
					
					local spawnLocations = {};
					for _, lib in pairs(modGpsLibrary:ListByKeyValue("WorldName", gpsLib.WorldName)) do
						if lib.SetSpawn == nil or lib.SetSpawn == gpsLib.SetSpawn then continue end;
						table.insert(spawnLocations, lib.SetSpawn);
					end
					
					local spawnName = spawnLocations[math.random(1, #spawnLocations)];
					local enemySpawnPart = workspace:FindFirstChild(spawnName) or workspace:FindFirstChildWhichIsA("SpawnLocation");
					
					Debugger:StudioLog("spawnLocations", spawnLocations, "enemySpawnPart",enemySpawnPart);
					
					--Pick faction
					local enemyFacInfo = {Icon="9890634236";};
					local globalFactionMetaList = modFactions.GetGlobalMetaList();
					
					if globalFactionMetaList then
						local list = {};
						for key, _ in pairs(globalFactionMetaList.List) do
							if key ~= factionTag then
								table.insert(list, key);
							end
						end
						
						Debugger:StudioLog("Pick random faction ", list);
						local pick = #list > 0 and globalFactionMetaList.List[list[math.random(1, #list)]] or nil;
						if pick == nil then
							Debugger:Warn("Use placeholder faction data");
							pick = {
								Tag="apex";
								Title="Apex Legion";
								Icon="7702620744";
								Color="ff3c3c";
							};
						end
						Debugger:StudioLog("Picked ",pick);
						enemyFacInfo.Tag = pick.Tag;
						enemyFacInfo.Title = pick.Title;
						enemyFacInfo.Icon = pick.Icon;
						enemyFacInfo.Color = pick.Color;
					end
					--
					
					local enemyBanner = game.ReplicatedStorage.Prefabs.Items.factionbanner:Clone();
					enemyBanner:SetAttribute("SpawnTick", tick());

					local primaryPart = enemyBanner:WaitForChild("Handle");
					primaryPart.Anchored = true;

					local bannerPart = enemyBanner:WaitForChild("banner");
					for _, decal in pairs(bannerPart:GetChildren()) do
						if decal:IsA("Decal") then
							decal.Texture = "rbxassetid://".. enemyFacInfo.Icon;
						end
					end
					
					for _, obj in pairs(enemyBanner:GetChildren()) do
						if obj.Name == "flag" then
							obj.Color = Color3.fromHex(enemyFacInfo.Color);
						end
					end

					local halfSize = enemySpawnPart.Size/2;
					local pos = enemySpawnPart.Position;
					pos = pos + Vector3.new(math.random(-halfSize.X, halfSize.X), halfSize.Y, math.random(-halfSize.Z, halfSize.Z));

					enemyBanner:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0));
					enemyBanner.Name = "Enemy faction banner";
					enemyBanner.Parent = workspace.Environment;
					modReplicationManager.ReplicateOut({player}, enemyBanner);

					local bannerDestructible = require(enemyBanner:WaitForChild("Destructible"));
					
					bannerDestructible.MaxHealth = 50000;
					bannerDestructible.Health = bannerDestructible.MaxHealth;
					
					bannerDestructible.NetworkOwners = {player};
					
					task.delay(300, function()
						bannerDestructible.NetworkOwners = nil;
						bannerDestructible.Enabled = true;
					end)
					
					local function onEnemyBannerDestroy()
						if mission.Type ~= 1 then return end;

						shared.Notify(player, "Enemy faction banner was destroyed.", "Inform");
						Debugger:Warn("Destroyed faction banner ", enemyFacInfo);

						mission.SaveData.FactionData = {
							EnemyTag = enemyFacInfo.Tag;
						};
						
						if game.Players:IsAncestorOf(player) then
							modMission:CompleteMission(player, 60);
						end
					end
					enemyBanner.Destroying:Connect(onEnemyBannerDestroy);
					bannerDestructible.OnDestroy = onEnemyBannerDestroy;
					bannerDestructible.Enabled = true;

					
				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;