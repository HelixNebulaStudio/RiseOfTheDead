local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");

local modItemLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGpsLibrary = shared.require(game.ReplicatedStorage.Library.GpsLibrary);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

local MISSION_ID = 60;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modFactions = shared.require(game.ServerScriptService.ServerLibrary.Factions);
	
	shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
		local player: Player? = event.Player;
		if player == nil then return end;

		local id: string, interactable: InteractableInstance = ...;
		if id == nil or interactable == nil then return end;

		task.spawn(function()
			if id == "mission60RepairBanner" then
				local interactPart = interactable.Part;
				local interactObjectFactionTag = interactPart.Parent:GetAttribute("FactionTag");
				
				for _, oPlayer in pairs(game.Players:GetPlayers()) do
					local profile = shared.modProfile:Get(oPlayer);
					if profile == nil then continue end;
					
					local factionTag = tostring(profile.Faction.Tag);
					
					if factionTag == interactObjectFactionTag then
						modMission:Progress(oPlayer, MISSION_ID, function(mission)
							if mission.ProgressionPoint == 1 then
								shared.Notify(oPlayer, `{player.Name} has repaired the faction banner.`, "Reward");
								mission.ProgressionPoint = 2;
							end
						end)

						interactable.Config:SetAttribute("_Label", `Join: {interactable.Values.FactionTag}`);
						interactable.CanInteract = false;
						interactable:Sync();
					end
				end
			end
		end)
	end)
	
	bannersFolder = Instance.new("Folder");
	bannersFolder.Name = "BannersFolder";
	bannersFolder.Parent = workspace:WaitForChild("Environment");
	
	--==

	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		Debugger:StudioLog("mission.SaveData", mission.SaveData);
		local profile = shared.modProfile:Get(player);
		Debugger:StudioLog("profile.Faction", profile.Faction);

		local factionTag = tostring(profile.Faction.Tag);
		local factionTitle = profile.Faction.FactionTitle;
		local factionIcon = profile.Faction.FactionIcon;
		local factionColor = profile.Faction.FactionColor;
		
		local gpsLib = modGpsLibrary:FindByKeyValue("Name", mission.SaveData.Location);
		
		if not modBranchConfigurations.IsWorld(gpsLib.WorldName) then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
		
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
					
					local factionBannerInteractConfig = modInteractables.createInteractable("Button");
					factionBannerInteractConfig:SetAttribute("_Id", "mission60RepairBanner");
					factionBannerInteractConfig:SetAttribute("_Label", "Repair Faction Banner");
					factionBannerInteractConfig:SetAttribute("_InteractDuration", 5);
					factionBannerInteractConfig.Parent = factionbannerPrefab;

					local factionBannerInteractable: InteractableInstance = modInteractables.getOrNew(factionBannerInteractConfig);
					factionBannerInteractable.Values.FactionTag = factionTag;

					local saveData = mission.SaveData;
					local itemLib = modItemLibrary:Find(saveData.RepairItemId);
						
					factionBannerInteractable.Label = `Repair Faction Banner with {saveData.RepairCost} {itemLib.Name}.`;
					factionBannerInteractable:Sync();
					
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

					local destructibleConfig = modDestructibles.createDestructible("Generic");
					destructibleConfig:SetAttribute("DebrisName", "factionbanner");
					destructibleConfig.Parent = factionbannerPrefab;
					local bannerDestructible: DestructibleInstance = modDestructibles.getOrNew(
						destructibleConfig
					);
					bannerDestructible.HealthComp:SetMaxHealth(50000);
					bannerDestructible.HealthComp:Reset();
					bannerDestructible:SetEnabled(false);
					
					task.delay(300, function()
						local bannerDestructible: DestructibleInstance = modDestructibles.getOrNew(
							factionbannerPrefab.Destructible
						);
						if bannerDestructible then
							bannerDestructible.HealthComp:SetMaxHealth(50000);
							bannerDestructible.HealthComp:Reset();
							bannerDestructible:SetEnabled(true);
						end
					end)
					
				elseif mission.ProgressionPoint == 2 then
					local factionbannerPrefab = bannersFolder:FindFirstChild(factionTitle);
					if factionbannerPrefab then
						factionbannerPrefab:SetAttribute("Repaired", true);
						
						local bannerDestructible: DestructibleInstance = modDestructibles.getOrNew(
							factionbannerPrefab:FindFirstChild("Destructible")
						);
						if bannerDestructible then
							bannerDestructible:SetEnabled(true);
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

					local destructibleConfig = modDestructibles.createDestructible("Generic");
					destructibleConfig:SetAttribute("DebrisName", "factionbanner");
					destructibleConfig.Parent = enemyBanner;
					
					local bannerDestructible: DestructibleInstance = modDestructibles.getOrNew(
						destructibleConfig
					);
					if bannerDestructible then
						bannerDestructible.NetworkOwners = {player};
						bannerDestructible.HealthComp:SetMaxHealth(50000);
						bannerDestructible.HealthComp:Reset();
						bannerDestructible:SetEnabled(false);
					end
					
					task.delay(300, function()
						bannerDestructible.NetworkOwners = (nil :: any);
						bannerDestructible:SetEnabled(true);
					end)
					
					local function onEnemyBannerDestroy()
						if mission.Type ~= 1 then return end;

						shared.Notify(player, "Enemy faction banner was destroyed.", "Inform");
						Debugger:Warn("Destroyed faction banner ", enemyFacInfo);

						mission.SaveData.FactionData = {
							EnemyTag = enemyFacInfo.Tag;
						};
						
						if game.Players:IsAncestorOf(player) then
							modMission:CompleteMission(player, MISSION_ID);
						end
					end
					enemyBanner.Destroying:Connect(onEnemyBannerDestroy);
					bannerDestructible.OnDestroy:Connect(onEnemyBannerDestroy);
					bannerDestructible:SetEnabled(true);
					
				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;