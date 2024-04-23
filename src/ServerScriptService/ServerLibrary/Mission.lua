local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Mission = {};
--== Variables;

local hours32Sec = 86400 + 43200;

local RunService = game:GetService("RunService");

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

local remotes = game.ReplicatedStorage.Remotes;

local remoteMissionRemote = modRemotesManager:Get("MissionRemote");
local remoteHudNotification = modRemotesManager:Get("HudNotification");

local remoteMissionCheckFunction = remotes.Interface.MissionCheckFunction;
local remotePinMission = remotes.Interface.PinMission;
local bindPlayServerScene = remotes.Cutscene.PlayServerScene;

--== Script;
Mission.MissionProfiles = {};

Mission.MissionType = {Active=1; Available=2; Completed=3; Failed=4};
Mission.FailCauses = {Timeout=1; Died=2; Removed=3; Expired=4; Abort=5;};

Mission.OnPlayerMission = modEventSignal.new("OnPlayerMission");

local function CheckWorld(world)
	--if RunService:IsStudio() then Debugger:Log("Skip world check for studio.") return true end;
	
	local currentWorld = modBranchConfigs.GetWorld();
	if world == nil then
		return true;
	elseif type(world) == "string" then
		return world == currentWorld;
	elseif type(world) == "table" then
		for a=1, #world do
			if world[a] == currentWorld then
				return true;
			end
		end
	end
	return false;
end

function Mission.GetMissions(playerName)
	local profile = shared.modProfile.GetByName(playerName);
	local activeSave = profile and profile:GetActiveSave();
	local missionsProfile = activeSave and activeSave.Missions;
	
	return missionsProfile;
end

function Mission:GetMission(player, missionId)
	if player == nil then return end;
	local missionProfile = self.GetMissions(player.Name);
	local mission = missionProfile and missionProfile:Get(missionId) or nil;
	return mission;
end

function Mission:IsComplete(player, missionId)
	if player == nil then return end;
	local mission = Mission:GetMission(player, missionId)
	return mission and mission.Type == Mission.MissionType.Completed or false;
end

function Mission:IsAvailable(player, missionId)
	if player == nil then return end;
	local missionProfile = self.GetMissions(player.Name);
	local mission = missionProfile and missionProfile:Get(missionId) or nil;
	return mission and mission.Type == Mission.MissionType.Available or false;
end

function Mission:Progress(player, missionId, func: ((mission: {[any]:any})->boolean)?)
	if player == nil then return end;
	local missionProfile = self.GetMissions(player.Name);
	local mission = missionProfile and missionProfile:Get(missionId) or nil;
	
	if mission and mission.Type == Mission.MissionType.Active then
		if func then
			local progressionPoint = mission.ProgressionPoint;
			
			local objectivesCompleted = 0;
			for _,v in next, (mission.ObjectivesCompleted or {}) do
				if v == true then 
					objectivesCompleted = objectivesCompleted +1; 
				end 
			end
			
			local sync = func(mission);
			local changedObjectives = 0; for _,v in next, (mission.ObjectivesCompleted or {}) do if v == true then changedObjectives = changedObjectives +1; end end
			
			if mission.ProgressionPoint ~= progressionPoint or objectivesCompleted ~= changedObjectives then
				
				missionProfile:Pin(missionId, true);
				mission.Changed:Fire(false, mission);
				missionProfile.OnMissionChanged:Fire(mission);
				
			end
			if sync ~= false then
				missionProfile:Sync();
			end
		end
		return mission;
	end

	return;
end

function Mission:SetData(player, missionId, key, value)
	local missionProfile = self.GetMissions(player.Name);
	local mission = missionProfile and missionProfile:Get(missionId) or nil;
	if mission then
		mission.SaveData[tostring(key)] = value;
		return true;
	end
	return false;
end

function Mission:GetData(player, missionId, key)
	local missionProfile = self.GetMissions(player.Name);
	local mission = missionProfile and missionProfile:Get(missionId) or nil;
	return mission and mission.SaveData[tostring(key)] or nil;
end

function Mission:Pin(player, missionId, value)
	local missionProfile = self.GetMissions(player.Name);
	missionProfile:Pin(missionId, value);
end

function Mission:CanCompleteMission(player, missionId, announce)
	local profile = shared.modProfile:Get(player);
	local activeInventory = profile.ActiveInventory;
	local library = modMissionLibrary.Get(missionId);
	
	if library.Rewards then
		local list = {};
		for a=1, #library.Rewards do
			local reward = library.Rewards[a];
			if reward.Type == "Item" then
				table.insert(list, {ItemId=reward.ItemId; Data={Quantity=(reward.Quantity or 1)};});
			end
		end
		local hasSpace = activeInventory:SpaceCheck(list);
		if not hasSpace then
			if announce then
				shared.Notify(player, "Not enough inventory space to receive mission reward.", "Negative");
			end
			return false;
		end
	end

	return true;
end

-- !outline: Mission:CompleteMission
function Mission:CompleteMission(players, missionId, sync)
	players = type(players) == "table" and players or {players};
	sync = sync or true;
	for a=1, #players do
		local player = players[a];
		local missionProfile = self.GetMissions(player.Name);
		local mission = missionProfile and missionProfile:Get(missionId) or nil;
		local library = modMissionLibrary.Get(missionId);
		
		if mission == nil then
			mission = missionProfile:Add(missionId, false);
		end
		
		if mission and mission.Type ~= Mission.MissionType.Completed then
			if mission.Redo then
				mission.Type = Mission.MissionType.Completed;
				mission.Pinned = nil;
				mission.Changed:Fire(true, mission);
				missionProfile.OnMissionChanged:Fire(mission);
				
				mission.Redo = nil;
				missionProfile:Sync();
				remoteHudNotification:FireClient(player, "MissionComplete", {Name=library.Name;});
				
				return;
			end
			
			if not Mission:CanCompleteMission(player, missionId, true) then return; end;
			
			remoteHudNotification:FireClient(player, "MissionComplete", {Name=library.Name;});
			mission.Type = Mission.MissionType.Completed;
			mission.Pinned = nil;
			mission.Changed:Fire(false, mission);
			mission.CompletionTime = os.time();
			missionProfile.OnMissionChanged:Fire(mission);
			Mission.OnPlayerMission:Fire(player, mission, "complete");
			
			
			local pinnedNextActive = false;
			for b=1, #missionProfile do
				local bMission = missionProfile[b];
				if bMission.Type == Mission.MissionType.Active then
					pinnedNextActive = true;
					missionProfile:Pin(bMission.Id, true, false);
					break;
				end
			end
			
			if library.LinkNextMission then
				local nextMission = missionProfile:Get(library.LinkNextMission);
				if nextMission and nextMission.Type ~= Mission.MissionType.Completed then
					pinnedNextActive = true;
					missionProfile:Pin(nextMission.Id, true, false);
					break;
				end
			end
			
			if library.Rewards and (library.MissionType == modMissionLibrary.MissionTypes.Repeatable or modEvents:GetEvent(player, "MRID"..missionId) == nil) then
				
				modEvents:NewEvent(player, {Id="MRID"..missionId;});
				
				local profile = shared.modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local activeInventory = profile.ActiveInventory;
				local unlockedMission = false;
				local tweakPointsNotifed = false;
				
				for a=1, #library.Rewards do
					local reward = library.Rewards[a];
					if reward.Type == "Perks" then
						if playerSave and playerSave.AddStat then
							local perkAmount = reward.Amount;
							
							playerSave:AddStat("Perks", perkAmount);
							shared.Notify(player, ("You recieved $Amount Perks and 3 Tweak Points for completing $Name."):gsub("$Amount", perkAmount):gsub("$Name", library.Name), "Reward");
							tweakPointsNotifed = true;
							
							if library.MissionType == 1 then
								modAnalytics.RecordResource(player.UserId, 1, "Source", "Perks", "Gameplay", "Core Missions");
							elseif library.MissionType == 4 then
								modAnalytics.RecordResource(player.UserId, 1, "Source", "Perks", "Gameplay", "Board Missions");
							else
								modAnalytics.RecordResource(player.UserId, 1, "Source", "Perks", "Gameplay", "Missions");
							end
						end
						
					elseif reward.Type == "Money" then
						if playerSave and playerSave.AddStat then
							playerSave:AddStat("Money", reward.Amount);
							shared.Notify(player, string.gsub("You recieved $$Amount for completing $Name.", "$Amount", reward.Amount):gsub("$Name", library.Name), "Reward");
						end
						
					elseif reward.Type == "Item" then
						if activeInventory == nil then return "Missing active inventory."; end;
						local itemLibrary = modItemsLibrary:Find(reward.ItemId);
						activeInventory:Add(reward.ItemId, {Quantity=reward.Quantity;}, function(queueEvent, storageItem)
							shared.Notify(player, "You recieved "..(reward.Quantity > 1 and reward.Quantity.." "..itemLibrary.Name or "a "..itemLibrary.Name).." for completing "..library.Name..".", "Reward");
							
							modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
						end);
						
					elseif reward.Type == "Mission" then
						unlockedMission = true;
						Mission:AddMission(player, reward.Id);
					end
				end
				playerSave:AddStat("TweakPoints", 3);
				profile:AddPlayPoints(120);
				if tweakPointsNotifed == false then
					shared.Notify(player, "You recieved 3 Tweak Points for completing "..library.Name..".", "Reward");
				end
				
				if unlockedMission then
					shared.Notify(player, "Press [B] to open your missions menu.", "Inform");
				end
				
				task.spawn(function()
					local rbxPerksFlag = profile.Flags:Get("rbxPremiumPerks") or {Id="rbxPremiumPerks"; JoinTime=0; MissionsComplete=0; CompleteTime=0;};
					
					if player.MembershipType == Enum.MembershipType.Premium or profile.Premium then
						if rbxPerksFlag.MissionsComplete < 3 then
							rbxPerksFlag.MissionsComplete = rbxPerksFlag.MissionsComplete +1;
							
							if rbxPerksFlag.MissionsComplete < 3 then
								shared.Notify(player, "Complete ".. rbxPerksFlag.MissionsComplete .."/3 missions for a bonus +35 Perks!", "Positive");
								
							else
								shared.Notify(player, "+35 Perks from Premium Bonus!", "Positive");
								playerSave:AddStat("Perks", 35);
								modAnalytics.RecordResource(player.UserId, 35, "Source", "Perks", "Gameplay", "PremiumBonus");
								rbxPerksFlag.CompleteTime = os.time();
							end
							
							profile.Flags:Add(rbxPerksFlag);
						end
					end
				end)
				
				modAnalytics.RecordProgression(player.UserId, "Complete", "Mission:"..library.MissionId);

				--== Battlepass
				local battlePassSave = missionProfile.Profile.BattlePassSave;
				if battlePassSave then
					battlePassSave:OnMissionComplete(mission);
				end

			end
			
			
			if not pinnedNextActive then
				for b=1, #missionProfile do
					local bMission = missionProfile[b];
					if bMission.Type == Mission.MissionType.Available then
						local bMissionLib = modMissionLibrary.Get(bMission.Id);
						if bMissionLib.MissionType == modMissionLibrary.MissionTypes.Core then
							missionProfile:Pin(bMission.Id, true, false);
							break;
						end
					end
				end
			end
			
			if sync then
				missionProfile:Sync();
			end
			
		else
			if missionProfile == nil then
				Debugger:WarnClient(player, "Missing mission profile!");
			elseif mission == nil then
				Debugger:WarnClient(player, "Could not get mission ("..missionId..")");
			end
		end
	end

	return;
end

function Mission:StartMission(player, missionId, func, sync, force)
	sync = sync or true;
	local missionProfile = self.GetMissions(player.Name);
	if missionProfile then
		local success, failReasons = missionProfile:Start(missionId, force);
		if func then
			func(success, failReasons);
		end
		if success and sync then
			missionProfile:Sync();
		end
	end
end

function Mission:FailMission(player, missionId, failCause, sync)
	sync = sync or true;
	local missionProfile = self.GetMissions(player.Name);
	if missionProfile then
		missionProfile:Failed(missionId, failCause);
		if sync then
			missionProfile:Sync();
		end
	end
end

function Mission:CanStartMission(player, missionId)
	local missionProfile = self.GetMissions(player.Name);
	if missionProfile then
		return missionProfile:CanStart(missionId);
	end
	return false, "Missing mission profile";
end

function Mission:CanAddMission(player, missionId)
	local missionProfile = self.GetMissions(player.Name);
	if missionProfile then
		return missionProfile:CanAdd(missionId);
	end
	return false, "Missing mission profile";
end

function remoteMissionCheckFunction.OnServerInvoke(player, missionId)
	return Mission:CanStartMission(player, missionId);
end

function Mission:GetNpcMissions(player, missionGiverName)
	local missionList = {};
	
	local missionProfile = self.GetMissions(player.Name);
	if missionProfile == nil then return missionList; end;
	
	for b=1, #missionProfile do
		local mission = missionProfile[b];
		
		local library = modMissionLibrary.Get(mission.Id);
		if library.From == missionGiverName and (mission.Type == Mission.MissionType.Available or mission.Type == Mission.MissionType.Active) then
			table.insert(missionList, mission);
		end
	end
	
	return missionList;
end

function Mission:AddMission(players, missionId, sync, force, dataOverwrite)
	if type(players) ~= "table" then players = {players}; end;
	sync = sync or true;
	for a=1, #players do
		local player = players[a];
		local missionProfile = self.GetMissions(player.Name);
		if missionProfile then
			missionProfile:Add(missionId, nil, force, dataOverwrite);
			missionProfile:UpdateObjectives();
			if sync then
				missionProfile:Sync();
			end
		end
	end
end

function Mission:RedoMission(player, missionId)
	local mission = Mission:GetMission(player, missionId);
	
	if mission == nil then return end;
	if mission.Type == 3 then
		local library = modMissionLibrary.Get(missionId);
		
		if library.CanRedo then
			if modEvents:GetEvent(player, "MRID"..missionId) == nil then
				modEvents:NewEvent(player, {Id="MRID"..missionId;});
			end
			
			local missionProfile = Mission.GetMissions(player.Name);
			for a=1, #missionProfile do
				if missionProfile[a].Redo then
					Mission:CompleteMission(player, missionProfile[a].Id, false);
				end
			end

			mission.Redo = true;
			mission.Type = 2;
			mission.ProgressionPoint = 1;
			missionProfile:Pin(missionId, true);
			missionProfile:Sync();
			mission.Changed:Fire(false, mission);
			missionProfile.OnMissionChanged:Fire(mission);

			shared.Notify(player, "Redoing mission, "..library.Name..".", "Inform");
			
			if library.CanRedo.Travel then
				modServerManager:Travel(player, library.CanRedo.Travel);
			end
		end
	end
end

function remoteMissionRemote.OnServerInvoke(player, actionId, missionId)
	if remoteMissionRemote:Debounce(player) then return nil end;
	
	if actionId == "Redo" then
		Mission:RedoMission(player, missionId);
		
	elseif actionId == "Abort" then
		local missionProfile = Mission.GetMissions(player.Name);

		missionProfile:Failed(missionId, Mission.FailCauses.Abort);
		missionProfile:Pin(missionId, false);
		
	elseif actionId == "MissionBoardStart" then
		local returnPacket = {};
		
		local missionProfile = Mission.GetMissions(player.Name);
		local mission = missionProfile:Get(missionId);
		
		if mission == nil or mission.Type == 1 or mission.Type == 3 then
			returnPacket.FailMsg = mission == nil and "Invalid mission" or "Mission already active or completed";
			return returnPacket;
		end
		
		local listOfRepeatable = missionProfile:GetCatTypes(modMissionLibrary.MissionTypes.Repeatable);
		
		local hasActive = false;
		for a=1, #listOfRepeatable do
			local repeatableMission = listOfRepeatable[a];
			if repeatableMission.Type == 1 then -- Active
				hasActive = true;
				break;
			end
		end
		
		if hasActive then
			returnPacket.FailMsg = "A mission from the mission board is already active";
			return returnPacket;
		end
		
		Mission:StartMission(player, missionId);
		
		return returnPacket;
	end

	return;
end

function Mission.NewList(profile, syncFunc)
	local listMeta = {
		PinCooldown = nil;
	};
	listMeta.__index = listMeta;
	
	local player = profile.Player;
	
	listMeta.Profile = profile;
	listMeta.Player = player;
	listMeta.Loaded = false;
	listMeta.Sync = syncFunc;
	
	listMeta.OnMissionChanged = modEventSignal.new("OnMissionChanged");
	
	local list = setmetatable({}, listMeta);
	
	local function NewMission(input)
		local library = modMissionLibrary.Get(input.Id);
		if library == nil then return end;
		if input.AddTime == nil then input.AddTime = os.time() end;
		if input.StartTime == nil then input.StartTime = os.time() end;
		
		local addTimeLapse = os.time()-input.AddTime;
		local _startTimeLapse = os.time()-input.StartTime;
		if library.ExpireTime and addTimeLapse >= library.ExpireTime then return end;
		--if library.Timer and startTimeLapse >= library.Timer then return end;
		
		if library.MissionType == modMissionLibrary.MissionTypes.Repeatable and input.Type == Mission.MissionType.Completed then
			local timeSinceCompletion = os.time()-(input.CompletionTime or 0);
			if timeSinceCompletion >= modMissionLibrary.RepeatableMissionCooldown then
				Debugger:Warn("Remove old repeatable mission ", library.Name);
				return;
			end
		end
		
		local requirements = library.AddRequirements;
		if requirements then
			if requirements.SpecialEvent and not modConfigurations.SpecialEvent[requirements.SpecialEvent] then return end
		end
		
		local missionObjectMeta = {};
		missionObjectMeta.__index = missionObjectMeta;
		missionObjectMeta.Player = player;
		missionObjectMeta.Cache = {};
		missionObjectMeta.Library = library;
		missionObjectMeta.Changed = modEventSignal.new("OnMissionChanged");
		
		local missionObject = setmetatable({
			Id=input.Id;
			Type=input.Type or Mission.MissionType.Available;
			Expiration=input.Expiration;
			CompletionTime=input.CompletionTime;
			StartTime=input.StartTime;
			AddTime=input.AddTime;
			ProgressionPoint=input.ProgressionPoint or (library.Progression and 1) or (library.Checkpoint and 1);
			ObjectivesCompleted=input.ObjectivesCompleted or (library.Objectives and {});
			SaveData=input.SaveData or {};
			FailTag=input.FailTag;
			Pinned=input.Pinned;
			Redo=input.Redo;
			
			CatType=library.MissionType;
		}, missionObjectMeta);
			
		if input.SaveData == nil then
			for k, v in pairs(library.SaveData or {}) do
				if type(v) == "function" then
					missionObject.SaveData[k] = v(missionObject);
				else
					missionObject.SaveData[k] = v;
				end
			end
		end
		
		task.spawn(function()
			local missionLogic = library.LogicScript;
			if missionLogic then
				local modMissionFuncs = require(missionLogic);
				if modMissionFuncs and modMissionFuncs.Init then
					modMissionFuncs.Init(list, missionObject);
				end
				
				task.spawn(function()
					remoteMissionRemote:InvokeClient(player, "init", missionObject.Id, missionLogic);
				end)
			end
			
		end)
		
		if library.CompleteAfterObjectives == true then
			missionObjectMeta.Changed:Connect(function()
				if missionObject.Type ~= Mission.MissionType.Active then return end;
				
				if list:IsObjectivesComplete(missionObject.Id) then
					Mission:CompleteMission(player, missionObject.Id);
				end
			end)
		end
		
		return missionObject;
	end
	
	function listMeta:UpdateObjectives()
		local profile = shared.modProfile:Get(player);
		if profile == nil then return end;
		
		local playerSave = profile:GetActiveSave();
		
		local updated = false;
		for a=1, #list do
			local mission = list[a];
			local library = modMissionLibrary.Get(mission.Id);
			
			local function updateObjective(objectiveId, objective)
				if objective.Type == "RequireItem" then
					local itemId = objective.ItemId;
					local amount = objective.Amount;

					if objective.ItemIdOptions and mission.SaveData.ItemId then
						itemId = mission.SaveData.ItemId;
					end
					if objective.AmountRange and mission.SaveData.Amount then
						amount = mission.SaveData.Amount;
					end

					if amount and amount > 1 then
						local itemsCount = playerSave.Inventory:CountItemId(itemId);
						
						local tradeStorage = playerSave.Storages and playerSave.Storages[player.Name.."Trade"] or nil;
						if tradeStorage then
							itemsCount = itemsCount + tradeStorage:CountItemId(itemId);
						end
						
						mission.ObjectivesCompleted[objectiveId] = itemsCount >= amount and true or math.clamp(amount - itemsCount, 0, amount);
						
					else
						local item = playerSave.Inventory:FindByItemId(itemId);
						mission.ObjectivesCompleted[objectiveId] = item ~= nil or nil;
						
					end
					updated = true;
				end
				
				if mission.ObjectivesCompleted[objectiveId] == nil then
					mission.ObjectivesCompleted[objectiveId] = false;
				end
			end
			
			if library.Checkpoint then
				local checkpointInfo = library.Checkpoint[mission.ProgressionPoint];
				
				if checkpointInfo and checkpointInfo.Objectives then
					for a=1, #checkpointInfo.Objectives do
						local objId = checkpointInfo.Objectives[a];

						updateObjective(objId, library.Objectives[objId]);
					end
				end
				
			elseif library.Objectives then
				for objectiveId, objective in pairs(library.Objectives) do
					updateObjective(objectiveId, objective)
				end
				
			end
			
		end
		if updated then
			list:Sync();
		end
	end
	
	function listMeta:IsObjectivesComplete(missionId)
		local mission = self:Get(missionId);
		if mission == nil or mission.Type ~= Mission.MissionType.Active then return false end;
		
		local hasFalse = false;
		for k, v in pairs(mission.ObjectivesCompleted) do
			if v ~= true then
				hasFalse = true;
				break;
			end
		end
		
		return not hasFalse;
	end
	
	function listMeta:Load(rawData)
		Debugger:Log("Load missions: ", self.Player);
		
		local pinned = nil;
		for key, value in pairs(rawData or {}) do
			if typeof(value) ~= "table" then continue end;

			local mission = NewMission(value)
			if mission ~= nil then
				table.insert(list, mission);
				mission.Changed:Fire(false, mission);
				if mission.Pinned then
					self:Pin(mission.Id, true, false);
					pinned = mission.Id
				end;

				self.OnMissionChanged:Fire(mission);
			end
		end
		if pinned == nil then
			for a=1, #list do
				if list[a].Type == Mission.MissionType.Active then
					self:Pin(list[a].Id, true, false);
					break;
				end
			end
		end
		table.sort(list, function(A, B) return A.Id < B.Id end)
		
		if modBranchConfigs.IsWorld("MainMenu") then
			for a=1, #list do
				local mission = list[a];
				if mission.Redo then
					mission.Type = Mission.MissionType.Completed;
					mission.Pinned = nil;
					mission.Redo = nil;
				end
			end
		end
		
		task.spawn(function()
			local cutsceneLoaded = {};
			
			for a=1, #list do
				local lib = modMissionLibrary.Get(list[a].Id);
				if lib.Cutscene and CheckWorld(lib.World) then
					table.insert(cutsceneLoaded, list[a].Id);
					bindPlayServerScene:Invoke({player}, lib.Cutscene);
				end
			end
			
			if #cutsceneLoaded > 0 then
				Debugger:Log("Loading (",table.concat(cutsceneLoaded, ","),") mission cutscenes for",player.Name);
			end
			
			for a=1, #list do
				local mission = list[a];
				if mission.Redo then
					mission.Changed:Fire(false, mission);
					self.OnMissionChanged:Fire(mission);
				end
			end

			--mission streak buffer;
			local missionStreak = modEvents:GetEvent(player, "MissionStreak") or {
				Id="MissionStreak";
				Count=0;
				LastCompletion=os.time();
			};

			if missionStreak.LastCompletion == nil then
				missionStreak.LastCompletion = os.time();
			end
			if os.time()-missionStreak.LastCompletion >= hours32Sec then
				missionStreak.Count = 0;
				modEvents:NewEvent(player, missionStreak);
			end
			
			listMeta.Loaded = true;
		end);
		
		
		return self;
	end
	
	function listMeta:Get(missionId)
		for a=1, #self do
			if self[a].Id == missionId then
				return self[a], a;
			end
		end

		return;
	end
	
	function listMeta:Destroy(mission)
		for a=#self, 1, -1 do
			if self[a].StartTime == mission.StartTime then
				local lib = modMissionLibrary.Get(mission.Id);
				if lib.EventFlags then
					for a=1, #lib.EventFlags do
						local eventInfo = lib.EventFlags[a];
						if eventInfo.Clear then
							modEvents:RemoveEvent(player, eventInfo.Id);
						end
					end
				end
				
				if modEvents:GetEvent(player, "MRID"..mission.Id) ~= nil then
					modEvents:RemoveEvent(player, "MRID"..mission.Id);
				end
				
				mission.Changed:Fire(false, mission);
				self.OnMissionChanged:Fire(mission);
				table.remove(self, a);
				mission.Changed:Destroy();
				Debugger:Log("Destroying mission (",mission.Id,") from",self.Player.Name, debug.traceback());
				break;
			end
		end
	end

	function listMeta:GetCatTypes(catType)
		local t = {};
		for a=1, #self do
			if self[a].CatType == catType then
				table.insert(t, self[a]);
			end
		end
		return t;
	end
	
	function listMeta:GetTypes(missionTypes)
		local t = {};
		for a=1, #self do
			if self[a].Type == missionTypes then
				table.insert(t, self[a]);
			end
		end
		return t;
	end
	
	-- !outline: MissionProfile:Add
	function listMeta:Add(missionId, sync, force, dataOverwrite)
		if self:Get(missionId) ~= nil then
			warn("Mission>> Player(",player.Name,") failed to add existing mission(",missionId,").");
			return self:Get(missionId);
		end
		
		local library = modMissionLibrary.Get(missionId);
		if library == nil then
			warn("Mission>> Player(",player.Name,") tried to add non-existing mission(",missionId,").");
			return 
		end;
		
		if force ~= true and library.AddRequirements then
			if not self:CanAdd(missionId) then return; end
		end
		
		local mission = NewMission{Id=missionId; ProgressionPoint=((library.Progression or library.Checkpoint) and 1 or nil);};

		if dataOverwrite then
			for k, v in pairs(dataOverwrite) do
				mission.SaveData[k] = v;
			end
		end
		
		table.insert(list, mission);
		
		mission.Changed:Fire(false, mission);
		self.OnMissionChanged:Fire(mission);
		
		spawn(function()
			if library.Cutscene and CheckWorld(library.World) then
				bindPlayServerScene:Invoke({player}, library.Cutscene);
			end
		end);
		
		if sync ~= false then self:Sync(); end;
		
		shared.Notify(player, (("Mission \"$Name\" added."):gsub("$Name", library.Name)), "Reward");
		modEvents:NewEvent(player, {Id="lastAddedMission"..missionId; UnixTime=DateTime.now().UnixTimestamp;});

		return mission;
	end
	
	function listMeta:CanAdd(missionId, ignoreExist)
		local mission = self:Get(missionId);
		if ignoreExist ~= true and mission then return false, "Mission already exist."; end;

		local unixTime = DateTime.now().UnixTimestamp;
		
		local library = modMissionLibrary.Get(missionId);
		if library then
			if library.AddRequirements then
				local profile = shared.modProfile:Get(self.Player);
				local gameSave = profile:GetActiveSave();
				
				for _, rData in pairs(library.AddRequirements) do
					local rType = rData.Type;
					local rValue = rData.Value;
					
					if rType == "MissionCompleted" then
						for a=1, #rValue do
							local m = self:Get(rValue[a]);
							if m == nil or m.Type ~= Mission.MissionType.Completed then
								Debugger:Log("Player(",player.Name,") failed to add mission(",missionId,") MissionCompleted:",rValue[a],".");
								return false, "Mission requires Mission:"..rValue[a]..".";
							end;
						end
					end
					
					if rType == "Mission" then
						local m = self:Get(rData.Id);
						if m == nil or m.Type ~= Mission.MissionType.Completed then
							Debugger:Log("Player(",player.Name,") failed to add mission(",missionId,") Require Mission:",rData.Id,".");
							return false, "Mission requires Mission:"..rData.Id..".";
						end;
					end
					
					if rType == "Level" and (gameSave:GetStat("Level") or 0) < rValue then
						Debugger:Log("Player(",player.Name,") failed to add mission(",missionId,") Insufficient Level.");
						return false, "Mission requires Level:"..rValue..".";
					end
					
					if rType == "EventFlag" then
						local eventObj = modEvents:GetEvent(player, rData.Key);
						if eventObj == nil then
							return false, (rData.FailMsg or "You do not have access to this mission yet.");
							
						elseif typeof(rValue) == "function" then
							local checkV = rValue(eventObj);
							if checkV == false then
								return false, (rData.FailMsg or "You do not have access to this mission yet.");
							end
							
						elseif eventObj.Value ~= rValue then
							return false, (rData.FailMsg or "You do not have access to this mission yet.");
							
						end
					end
					
					if rType == "SpecialEvent" and not modConfigurations.SpecialEvent[rValue] then
						Debugger:Log("Player(",player.Name,") failed to add mission(",missionId,") Not SpecialEvent.");
						return false, "Mission can only be added on SpecialEvent:"..rValue..".";
					end
					
					if rType == "SafehomeNpcLimit" then
						local safehomeData = profile.Safehome;
						local active = 0;
						if safehomeData and safehomeData.Npc then
							for k,v in pairs(safehomeData.Npc) do
								if v.Active then
									active = active +1;
								end
							end
						end
						if active >= 5 then
							Debugger:Log("Player(",player.Name,") failed to add mission(",missionId,") exceeding safehome limit.");
							return false, "Mission exceeding safehome npc limit, use /resethomenpc.";
						end
					end
					
					if rType == "Cooldown" then
						local eventObj = modEvents:GetEvent(player, "lastAddedMission"..missionId);
						if eventObj and (unixTime-eventObj.UnixTime) < rValue then
							return false, "Mission is on cooldown.";
						end
					end
				end
			end
		else
			return false, "Mission does not exist.";
		end
		return true;
	end
	
	-- !outline: MissionProfile:CanStart
	function listMeta:CanStart(missionId)
		local mission = self:Get(missionId);
		local reasons = {};
		
		if mission then
			if mission.Type == Mission.MissionType.Active then
				table.insert(reasons, "Mission already started");
			elseif mission.Type == Mission.MissionType.Completed then
				table.insert(reasons, "Mission already completed");
			end
		end
		
		local library = modMissionLibrary.Get(missionId);
		local profile = shared.modProfile:Get(self.Player);
		if profile == nil then return false, {"Profile not loaded."}; end;
		
		local gameSave = profile:GetActiveSave();
		
		if library.StartRequirements then
			local requirements = library.StartRequirements;
			if requirements.Premium and not profile.Premium then
				table.insert(reasons, "Requires Premium");
			end
			if requirements.Level and (gameSave:GetStat("Level") or 0) < requirements.Level then
				table.insert(reasons, "Need Level "..requirements.Level.." or above");
			end
			if requirements.MissionCompleted then
				requirements.MissionCompleted = type(requirements.MissionCompleted) == "table" and requirements.MissionCompleted or {requirements.MissionCompleted};
				local requiredMissions = {};
				for a=1, #requirements.MissionCompleted do
					local rId = requirements.MissionCompleted[a];
					local m = self:Get(rId);
					if m == nil or m.Type ~= Mission.MissionType.Completed then
						local mData = modMissionLibrary.Get(rId);
						table.insert(requiredMissions, mData.Name);
					end
				end
				if #requiredMissions > 0 then
					table.insert(reasons, "Mission"..(#requiredMissions > 1 and "s: " or ": ")..table.concat(requiredMissions, ", "));
				end
			end
		end
		
		local activeMissionsCount = #self:GetTypes(Mission.MissionType.Active);
		local maxCount = (profile and profile.Premium and 5 or 3);
		if activeMissionsCount >= maxCount then
			table.insert(reasons, "Active missions full (".. activeMissionsCount .."/".. maxCount ..")");
		end
		
		if #reasons <= 0 then return true; end
		return false, reasons;
	end
	
	-- !outline: MissionProfile:Start
	function listMeta:Start(missionId, force)
		local mission = self:Get(missionId) or self:Add(missionId, false);
		local library = modMissionLibrary.Get(missionId);
		
		if force ~= true then
			local canStart, failReason = self:CanStart(missionId);
			if not canStart then
				return false, failReason;
			end
		end
		
		for a=1, #list do
			local listMission = list[a];
			if listMission.Redo then
				listMission.Type = Mission.MissionType.Completed;
				listMission.Pinned = nil;
				listMission.Redo = nil;
			end
		end
		
		mission.StartTime = os.time();
		mission.Type = Mission.MissionType.Active;

		mission.ProgressionPoint = 1;
		table.clear(mission.SaveData);

		if library.Objectives then
			for objId, obj in pairs(library.Objectives) do
				if obj.ItemIdOptions then
					mission.SaveData.ItemId = obj.ItemIdOptions[math.random(1, #obj.ItemIdOptions)];
				end
				if obj.Amount then
					mission.SaveData.Amount = obj.Amount;
				end
				if obj.AmountRange then
					mission.SaveData.Amount = math.random(obj.AmountRange.Min, obj.AmountRange.Max);
				end
			end
		end
		
		for k, v in pairs(library.SaveData or {}) do
			if type(v) == "function" then
				mission.SaveData[k] = v(mission);
			else
				mission.SaveData[k] = v;
			end
		end
		
		mission.Changed:Fire(false, mission);
		self.OnMissionChanged:Fire(mission);
		self:Pin(missionId, true);
		
		remoteHudNotification:FireClient(player, "MissionStart", {Name=library.Name;});
		modAnalytics.RecordProgression(player.UserId, "Start", "Mission:"..library.MissionId);
		
		listMeta:UpdateObjectives();
		return true;
	end
	
	function listMeta:Failed(missionId, failCause)
		local mission = self:Get(missionId);
		local library = modMissionLibrary.Get(missionId);
		if mission and library then
			if game.Players:IsAncestorOf(self.Player) and mission.Type ~= Mission.MissionType.Completed and mission.Type ~= Mission.MissionType.Failed then
				mission.Type = Mission.MissionType.Failed;
				remoteHudNotification:FireClient(self.Player, "MissionFail", {Name=library.Name;});
				
				local message = "Mission \""..library.Name.."\" failed because: ";

				if failCause == Mission.FailCauses.Expired then
					message = message .."Mission expired";
				elseif failCause == Mission.FailCauses.Timeout then
					message = message .."You ran out of time";
				elseif failCause == Mission.FailCauses.Died then
					message = message .."You died";
				elseif failCause == Mission.FailCauses.Removed then
					message = message .."It is removed";
				elseif failCause == Mission.FailCauses.Abort then
					message = message .."You aborted the mission";
				else
					message = message .. (failCause or "Unknown Reason");
				end
				
				mission.FailTag = failCause;
				shared.Notify(self.Player, message, "Negative");
				
				mission.Changed:Fire(false, mission);
				self.OnMissionChanged:Fire(mission);
				Mission.OnPlayerMission:Fire(player, mission, "failed");
				
				self:Sync();
				modAnalytics.RecordProgression(player.UserId, "Fail", "Mission:"..library.MissionId);
				
			else
				if mission.Type == Mission.MissionType.Failed then
					Debugger:Warn("Mission (",mission.Id,") already failed: ", mission.FailTag);
				end
				
			end
		else
			Debugger:Warn("Mission (",missionId,") failed does not exist in",mission == nil and "player data." or "library.");
		end
	end
	
	function listMeta:Pin(missionId, value, sync)
		local alreadyPinned = false;
		for a=1, #self do
			if self[a].Pinned ~= nil then
				if self[a].Id == missionId then alreadyPinned = true end;
				self[a].Pinned = nil;
			end;
		end
		local mission = self:Get(missionId);
		if mission then
			if alreadyPinned then
				if value == true then
					mission.Pinned = true;
				end
			else
				mission.Pinned = true;
			end
		end
		if sync ~= false then self:Sync(); end;
	end

	function listMeta:Tick()
		local osTime = os.time();
		for a=1, #self do
			local mission = self[a];
			if mission == nil then continue end;
			
			local missionLib = modMissionLibrary.Get(mission.Id);
			local addTimeLapse = os.time()-mission.AddTime;
			
			if missionLib.ExpireTime and addTimeLapse >= missionLib.ExpireTime then
				self:Failed(mission.Id, Mission.FailCauses.Expired);
				self:Destroy(mission);
			end
			
			local missionTimer = missionLib.Timer or mission.Timer;
			if missionTimer and mission.Type ~= Mission.MissionType.Available and mission.Type ~= Mission.MissionType.Failed then
				local startTimeLapse = osTime-mission.StartTime;
				if startTimeLapse >= missionTimer and mission.Type ~= Mission.MissionType.Failed then
					self:Failed(mission.Id, Mission.FailCauses.Timeout);
				end
			end
		end
	end
	
	listMeta.PinRemoteConnection = remotePinMission.OnServerEvent:Connect(function(player, missionId)
		if listMeta.Player == nil or not listMeta.Player:IsDescendantOf(game.Players) then listMeta.PinRemoteConnection:Disconnect(); return end;
		if player == listMeta.Player then
			if listMeta.PinCooldown == nil or tick()-listMeta.PinCooldown > 0.2 then
				listMeta.PinCooldown = tick();
				list:Pin(missionId);
			end
		end
	end)
	
	function listMeta.ObjectivesTracker()
		local profile = shared.modProfile:Get(player);
		local playerSave = profile and profile:GetActiveSave();
		
		if playerSave then
			playerSave.Inventory.OnChanged:Connect(function()
				if listMeta.Player == nil then return true end;
				listMeta:UpdateObjectives();

				return;
			end);
		end
		listMeta:UpdateObjectives();
	end
	
	function listMeta:Unload()
		Mission.MissionProfiles[player] = nil;
		for a=1, #self do
			local mission = self[a];
			mission.Changed:Destroy();
			for k, v in pairs(mission.Cache) do
				mission.Cache[k] = nil;
			end
		end
	end
	
	Mission.MissionProfiles[player] = list;
	
	return list;
end

modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
	for player, missionProfile in pairs(Mission.MissionProfiles) do
		if not player:IsDescendantOf(game.Players) then
			Mission.MissionProfiles[player] = nil;
			continue;
		end
		
		missionProfile:Tick();
	end
end)


task.spawn(function()
	Debugger.AwaitShared("modCommandsLibrary");
	shared.modCommandsLibrary:HookChatCommand("printmissioncache", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;

		RequiredArgs = 0;
		UsageInfo = "/printmissioncache";
		Description = [[Prints cache data for missions.]];

		Function = function(player, args)
			
			Debugger:WarnClient(player, modEvents:GetEvent(player, "MissionCache"));
			
			return true;
		end;
	});

	shared.modCommandsLibrary:HookChatCommand("printmissions", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;

		RequiredArgs = 0;
		UsageInfo = "/printmissions";
		Description = [[Prints missions.]];

		Function = function(player, args)
			local missionProfile = Mission.GetMissions(player.Name);
			
			if RunService:IsStudio() then
				print("missionProfile", missionProfile);
			else
				Debugger:Warn("missionProfile", missionProfile);
				Debugger:WarnClient(player, missionProfile);
			end

			return true;
		end;
	});
end)

shared.modMission = Mission;
return Mission;
