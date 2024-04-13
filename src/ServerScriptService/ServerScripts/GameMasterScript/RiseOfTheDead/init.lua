local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local ModEngine = {};
ModEngine.__index = ModEngine;

local CollectionService = game:GetService("CollectionService");

local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);

local modProfile = shared.modProfile;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGpsLibrary = require(game.ReplicatedStorage.Library.GpsLibrary);
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modItemSkinWear = require(game.ReplicatedStorage.Library.ItemSkinWear);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modMailObject = require(game.ServerScriptService.ServerLibrary.MailObject);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modWorldNaturalResource = require(game.ServerScriptService.ServerLibrary.WorldNaturalResource);

require(script.ShortFilmReward23);

local NameDisplayGui = script.Parent:WaitForChild("NameDisplay");

local random = Random.new();
--==

function ModEngine.OnPlayerAdded(player: Player)
	local profile = modProfile.new(player);
	
	--if #profile.Saves <= 0 then profile:NewSave(); end
	local playerSave = profile:GetActiveSave();
	
	local inventory = playerSave.Inventory;
	inventory.OnItemAdded:Connect(function(storageItem, quantity)
		if storageItem == nil then return end;
		modItemSkinWear.Generate(player, storageItem);
		
		local existCount = 0;
		for storgeId, storage in pairs(modStorage.GetPrivateStorages(player)) do
			local storageItem = storage:Find(storageItem.ID);
			
			if storageItem == nil then continue end;
			existCount = existCount+1;
			if existCount > 1 then
				break;
			end
		end
		
		if existCount > 1 then
			local lastOp = "";
			if inventory.LastRemote then
				lastOp = table.concat(inventory.LastRemote, ", ");
			end
			shared.modGameLogService:Log(player.Name.." Dup: "..storageItem.ItemId .. " Count: ".. existCount .." Remote: " .. lastOp , "DupCheck");
		end
	end)
	
	
	--== Auto-save cycle;
	task.spawn(function()
		repeat
			if profile and (os.time() - profile.LastOnline) > 300 then
				profile.LastOnline = os.time();
				profile:Save(); -- Auto save
			end
			if profile then profile:SyncMastery(); end
			
			task.wait(60);
		until modProfile:Find(player.Name) == nil;
		
		inventory.OnItemAdded:Destroy();
	end)

	local joinData = player:GetJoinData();
	local teleportData = joinData.TeleportData;
	if teleportData and teleportData.PreviousWorldName then
		profile.PreviousWorldName = teleportData.PreviousWorldName;
	end
	profile:InitMessaging();

	if playerSave then
		playerSave.Missions.ObjectivesTracker(); -- Activate objectives tracker;
		if modBranchConfigs.IsWorld("TheWarehouse") then
			local whereAmIMission = playerSave.Missions:Get(2);
			if whereAmIMission == nil then playerSave.Missions:Start(2); end
		end
		playerSave:CalculateLevel();
	end
	
	
	
	
	task.spawn(function()
		local playerGroupRank = 0;
		pcall(function()
			playerGroupRank = player:GetRankInGroup(4573862);
		end)
		if playerSave and playerGroupRank > 0 then
			playerSave:AwardAchievement("gromem");
			profile.GroupRank = playerGroupRank;
		end
		if modBranchConfigs.WorldInfo.DevsOnly and playerGroupRank < 200 and player.UserId > 0 then
			player:Kick();
			modAnalytics:ReportError("Security Alert", player.Name.." ("..player.UserId..") attempt to join staff world: "..modBranchConfigs.GetWorld(), "critical");
		end
		
		if modBranchConfigs.IsWorld("Main Menu") then return end;
		
		task.delay(5, function()
			-- !outline Premium bonus free perks
			if player.MembershipType == Enum.MembershipType.Premium or profile.Premium then

				local rbxPerksFlag = profile.Flags:Get("rbxPremiumPerks") or {Id="rbxPremiumPerks"; JoinTime=0; MissionsComplete=0; CompleteTime=0;};
				local joinPerks = 15;
				local cooldown = 72000;
				
				if os.time()-(rbxPerksFlag.JoinTime or 0) > cooldown then
					rbxPerksFlag.JoinTime = os.time();
					rbxPerksFlag.MissionsComplete = 0;
					
					profile.Flags:Add(rbxPerksFlag);

					playerSave:AddStat("Perks", joinPerks);
					shared.Notify(player, "+"..joinPerks.." Perks from Premium Daily Bonus. Complete 0/3 missions for a bonus +35 Perks!", "Positive");
					modAnalytics.RecordResource(player.UserId, joinPerks, "Source", "Perks", "Gameplay", "PremiumBonus");
				end
			end
		end)
	end)

	if #game.Players:GetPlayers() > 1 then
		local joinData = player:GetJoinData();
		if joinData.SourcePlaceId and modBranchConfigs.GetWorldDisplayName(joinData.SourcePlaceId) ~= "Main Menu" then
			local worldId = modBranchConfigs.GetWorldName(joinData.SourcePlaceId);
			local worldName = worldId and modBranchConfigs.GetWorldDisplayName(worldId) or worldId;
			shared.Notify(game.Players:GetPlayers(), player.Name.." has arrived from "..(worldName or "unknown")..".", "Inform");
			Debugger:Log(player.Name," has arrived from",worldName,".");
		else
			shared.Notify(game.Players:GetPlayers(), player.Name.." has entered the game.", "Inform");
			Debugger:Log(player.Name.." has entered the game.");
		end
	end

	if modBranchConfigs.WorldInfo.PublicWorld then
		if not profile.ReferredBy and profile.TrustLevel > 0 then
			local referrer;
			local followedPlayer = game.Players:GetPlayerByUserId(player.FollowUserId);
			if player.FollowUserId ~= 0 and followedPlayer then
				referrer = followedPlayer;
			else
				local oldestFirstJoin = os.time();
				local onlinePlayers = game.Players:GetPlayers();
				for _, otherPlayer in pairs(onlinePlayers) do
					local isFriend = false;
					pcall(function()
						isFriend = otherPlayer:IsFriendsWith(player.UserId);
					end)
					if otherPlayer ~= player and isFriend then
						local otherProfile = modProfile:Get(otherPlayer);
						if otherProfile.FirstJoined < oldestFirstJoin then
							oldestFirstJoin = otherProfile.FirstJoined;
							referrer = otherPlayer;
						end
					end
				end
			end
			if referrer then
				local referrerProfile = modProfile:Get(referrer);
				if #referrerProfile.ReferralList < 5 then
					local referrerSaveData = referrerProfile and referrerProfile:GetActiveSave();
					if referrerSaveData and referrerSaveData.NewMail then
						profile.ReferredBy = referrer.UserId;
						table.insert(referrerProfile.ReferralList, player.UserId);
						referrerSaveData:NewMail(modMailObject.new(modMailObject.Enum.Referral, {Name=player.Name;}));
						if #referrerProfile.ReferralList >= 5 then
							referrerSaveData:NewMail(modMailObject.new(modMailObject.Enum.ReferralComplete, {}));
						end
						referrerSaveData:SyncMail();
					end
				end
			end
		end
		
		--task.spawn(function()
		--	local sfc22 = require(script.ShortFilmReward22);
		--	sfc22.Player(player, profile);
		--end)
	end
	
	Debugger:Log("profile.PolicyData", profile.PolicyData);
	
	local classPlayer = modPlayers.Get(player);
	
	local arTick = tick();
	while game.Players:GetAttribute("AutoRespawn") ~= true do
		task.wait();
		if not game.Players:IsAncestorOf(player) then
			break;
		else
			if (tick()-arTick) >= 10 then
				Debugger:StudioWarn("Init spawn waiting for AutoRespawn attribute (",player,").");
				arTick = tick();
			end
		end
	end
	
	if game.Players:IsAncestorOf(player) then
		if player:GetAttribute("hm_2") then
			-- long loading?
			if math.random(1, 3) == 1 then
				task.wait(math.random(3, 12));
				if player:GetAttribute("hm_3") and math.random(1, 4) == 1 then
					-- kick unloadable;
					player:Kick("You have been kicked due to unexpected client behavior.");
					return;
				end
			end
		end
		classPlayer:Spawn();
	end
end

function ModEngine.OnPlayerRemoving(player)
	local exitMsg = false;
	local playerMeta = modPlayers.Get(player);
	if playerMeta and playerMeta.IsTeleporting and playerMeta.TeleportPlaceId then
		local worldId = modBranchConfigs.GetWorldName(playerMeta.TeleportPlaceId);
		local worldName = (modBranchConfigs.GetWorldDisplayName(worldId) or worldId)
		shared.Notify(game.Players:GetPlayers(), player.Name.." leaving to "..worldName..".", "Inform");
		Debugger:Log(player.Name.." leaving to "..worldName..".");
		exitMsg = true;
	end
	if not exitMsg then
		shared.Notify(game.Players:GetPlayers(), player.Name.." has left the game.", "Inform");
		Debugger:Log(player.Name.." has left the game.");
	end
end

function ModEngine.OnCharacterAdded(player, character)
	local classPlayer = modPlayers.Get(player);
	local profile = modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local traderProfile = profile.Trader;
	
	classPlayer.TimesSpawned = (classPlayer.TimesSpawned or 0) +1;
	
	profile:RefreshSettings();
	profile:UpdateTrustLevel();
	traderProfile:SyncGold();

	local humanoid = character:WaitForChild("Humanoid");
	humanoid.NameDisplayDistance = 0;

	local rootPart = character:WaitForChild("HumanoidRootPart");
	local spawnPos = rootPart.Position;

	local ff = Instance.new("ForceField");
	ff.Name = "SpawnProtection";
	ff.Visible = false;
	ff.Parent = character;
	
	task.delay(1, function()
		playerSave.AppearanceData:Update(playerSave.Clothing);
		
		if classPlayer.TimesSpawned == 1 then
			for a=1, 3 do
				classPlayer:SyncProperty("BodyEquipments");
				local remoteBodyEquipmentsSync = modRemotesManager:Get("BodyEquipmentsSync");
				remoteBodyEquipmentsSync:FireClient(player);
				task.wait(3);
			end
		end
	end)
	
	game.Debris:AddItem(ff, modConfigurations.SpawnProtectionTimer or 10);

	if playerSave then
		playerSave.LastHealth = math.max(10, playerSave.LastHealth or 10);
		classPlayer.DoInitHealth = playerSave.LastHealth;

		humanoid.Health = playerSave.LastHealth;

		classPlayer:OnNotIsAlive(function(character)
			playerSave.LastHealth = humanoid.MaxHealth*0.1;
			if playerSave.AddStat then playerSave:AddStat("Death", 1); end;
		end)
		humanoid.HealthChanged:Connect(function()
			if classPlayer.DoInitHealth then return end;
			playerSave.LastHealth = math.ceil(humanoid.Health);
		end)
		local spawnId = playerSave.Spawn;
		
		if modMission:IsComplete(player, 1) then
			playerSave:AwardAchievement("whami", false);
		end
		if not modMission:IsComplete(player, 7) and modBranchConfigs.GetWorld() == "TheWarehouse" then
			playerSave.Spawn = nil;
			spawnId = nil;
		end
		Debugger:Log("Spawning player (",player.Name,") on spawn id (",spawnId,").");

		local setSpawnCFrame = nil;
		if spawnId and workspace:FindFirstChild(spawnId) then
			local spawnPart = workspace[spawnId];

			local worldSpaceSize = spawnPart.CFrame:vectorToWorldSpace(spawnPart.Size);
			worldSpaceSize = Vector3.new(math.abs(worldSpaceSize.X), math.abs(worldSpaceSize.Y), math.abs(worldSpaceSize.Z));

			local newSpawnCFrame = spawnPart.CFrame * CFrame.new(random:NextNumber(-worldSpaceSize.X/2, worldSpaceSize.X/2), 2.35, random:NextNumber(-worldSpaceSize.Z/2, worldSpaceSize.Z/2));
			setSpawnCFrame = newSpawnCFrame;
		end
		if playerSave.Gps ~= "" then
			local gpsLib = modGpsLibrary:Find(playerSave.Gps);
			if gpsLib and gpsLib.Position and gpsLib.WorldName == modBranchConfigs.WorldName then
				setSpawnCFrame = CFrame.new(gpsLib.Position);
				playerSave.Gps = "";
				Debugger:Log("Gps spawn location set.");
				
			end
		end
		if setSpawnCFrame then
			Debugger:Log("Spawning on spawnId:", spawnId);
			
		else
			local spawnPart = nil;
			
			local availableSpawns = {};
			for _, obj in pairs(workspace:GetChildren()) do
				if obj:IsA("SpawnLocation") and obj.Enabled then
					table.insert(availableSpawns, obj);
				end
			end
			spawnPart = #availableSpawns > 0 and availableSpawns[math.random(1, #availableSpawns)] or nil;
			
			if spawnPart then
				local worldSpaceSize = spawnPart.CFrame:vectorToWorldSpace(spawnPart.Size);
				worldSpaceSize = Vector3.new(math.abs(worldSpaceSize.X), math.abs(worldSpaceSize.Y), math.abs(worldSpaceSize.Z));

				local newSpawnCFrame = spawnPart.CFrame * CFrame.new(random:NextNumber(-worldSpaceSize.X/2, worldSpaceSize.X/2), 2.35, random:NextNumber(-worldSpaceSize.Z/2, worldSpaceSize.Z/2));
				setSpawnCFrame = newSpawnCFrame;
				Debugger:Log("Spawning on random.");
			else
				setSpawnCFrame = CFrame.new(0, 10, 0);
				Debugger:Log("Spawning on origin.");
			end
		end
		
		profile.SpawnCFrame = setSpawnCFrame;
		classPlayer.SpawnCFrame = setSpawnCFrame;
		spawnPos = setSpawnCFrame.Position;
		
		task.delay(0, function()
			shared.modAntiCheatService:Teleport(player, setSpawnCFrame);
		end)

		playerSave:SumMasteries();
		playerSave.AppearanceData:Update(playerSave.Clothing);

		local perkCupcakes = modEvents:GetEvent(player, "perkCupcakes");
		
		if perkCupcakes ~= nil then
			if perkCupcakes.Remaining > 0 then
				task.spawn(function()
					task.wait(5);
					shared.Notify(player, "Your max perks have been turned into cupcakes, talk to Mason to claim them! Remaining: ".. (perkCupcakes.Remaining or 0), "Inform");

				end)
			end
			
		else
			local playerPerks = playerSave:GetStat("Perks");
			if playerPerks > modGlobalVars.MaxPerks then
				local perkCupcakes = modEvents:GetEvent(player, "perkCupcakes");

				if perkCupcakes == nil then
					local cupcakesCount = 0;
					
					if playerPerks > modGlobalVars.MaxPerks then
						cupcakesCount = math.floor((playerPerks-modGlobalVars.MaxPerks)/1000);
						playerPerks = playerPerks -(1000 * cupcakesCount);
					end
					
					if cupcakesCount > 0 then
						playerSave:AddStat("Perks", cupcakesCount * -1000);
						modEvents:NewEvent(player, {Id="perkCupcakes"; Max=cupcakesCount; Remaining=cupcakesCount;});
					end
				end
			end

		end

		local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
		local customizePacks = modItemsLibrary.Library:ListByKeyValue("UnlockPack", function(value)
			return value ~= nil;
		end)
		
		local function unlockCodex(packId, packType)
			for a=1, #customizePacks do
				local itemLib = customizePacks[a];
				if itemLib.UnlockPack and itemLib.UnlockPack.Type == packType and itemLib.UnlockPack.Id == packId then

					profile:UnlockItemCodex(itemLib.Id);
					
					break;
				end
			end
		end
		
		for packId, _ in pairs(profile.ColorPacks) do
			unlockCodex(packId, "Color");
		end
		for packId, _ in pairs(profile.SkinsPacks) do
			unlockCodex(packId, "Skin");
		end
		
		for baseItemId, list in pairs(profile.ItemUnlockables) do
			for itemId, _ in pairs(list) do
				profile:UnlockItemCodex(itemId);
			end
		end
		
	end
	
	-- Delete ff;
	task.spawn(function()
		task.wait(10);
		if not player:IsDescendantOf(game.Players) then return end;
		while player:IsDescendantOf(game.Players) do
			local newPos = rootPart.Position;
			if (newPos-spawnPos).Magnitude > 16 then
				break;
			end
			task.wait(1);
		end
		game.Debris:AddItem(ff, 1);
	end)


	local missionProfile = modMission.GetMissions(player.Name);
	if missionProfile then missionProfile:UpdateObjectives(); end

	spawn(function()
		local nameTagDisplay = NameDisplayGui:Clone();
		nameTagDisplay.Parent = rootPart;
		nameTagDisplay.Adornee = rootPart;

		profile:RefreshPlayerTitle();
		nameTagDisplay.Enabled = modConfigurations.ShowNameDisplays;
		CollectionService:AddTag(nameTagDisplay, "PlayerNameDisplays");
		local objectTag = Instance.new("ObjectValue");
		objectTag.Name = "PlayerTag";
		objectTag.Value = player;
		objectTag.Parent = nameTagDisplay;

		if profile.GamePass.PortableWorkbench then
			playerSave:AwardAchievement("theeng");
		end
		if profile.GamePass.VipTraveler then
			playerSave:AwardAchievement("viptra");
		end
	end)

	modLeaderboardService.Update();
end


task.spawn(function()
	local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

	Debugger.AwaitShared("modCommandsLibrary");
	shared.modCommandsLibrary:HookChatCommand("testerclaim", {
		Permission = shared.modCommandsLibrary.PermissionLevel.GameTester;

		RequiredArgs = 0;
		UsageInfo = "/testerclaim";
		Function = function(player, args)
			local profile = shared.modProfile:Get(player);
			local claimswordFlag = profile.Flags:Get("claimTesterSword");
			
			if claimswordFlag == nil then
				local hasSpace = profile.ActiveInventory:SpaceCheck{{ItemId="inquisitorssword";}};
				if hasSpace then
					profile.Flags:Add{Id="claimTesterSword"; Time=os.time()};
					profile.ActiveInventory:Add("inquisitorssword");
					
					shared.Notify(player, "You have successfully claim your Inquisitor's Sword!", "Positive");
					
				else
					shared.Notify(player, "Your inventory is full!", "Negative");
					
				end
			else
				shared.Notify(player, "You already claim the reward.", "Inform");
				
			end
			
			return true;
		end;
	});
	
	-- !outline: Set alliance
	shared.modCommandsLibrary:HookChatCommand("setally", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;

		RequiredArgs = 0;
		UsageInfo = "/setally [bandits/rats] [true/false]\nSet alliance with bandits and rats to true or false.";
		Function = function(player, args)
			local profile = shared.modProfile:Get(player);

			local missionCache = modEvents:GetEvent(player, "MissionCache");
			if missionCache and missionCache.Value then
				
				local fac = args[1];
				local bool = args[2] == true;
				
				if string.lower(fac) == "bandits" then
					fac = "BanditsAllied"
				elseif string.lower(fac) == "rats" then
					fac = "RatsAllied"
				else
					shared.Notify(player, "Invalid alliance, bandits or rats?", "Negative");
					return;
				end
				
				missionCache.Value[fac] = bool;
				shared.Notify(player, "Set alliance (".. fac ..") to ".. tostring(bool) ..".", "Inform");
				
				modEvents:SyncEvent(player, "MissionCache")
			end
			
			return true;
		end;
	});
end)

return ModEngine;
