local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
while shared.MasterScriptInit  ~= true do task.wait() end;

--== Variables;
Debugger.AwaitShared("modProfile");

local RunService = game:GetService("RunService");

local modDialogues = require(game.ServerScriptService.ServerLibrary.DialogueSave);
local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

local remoteProgressMission = modRemotesManager:Get("ProgressMission");

local Prefabs = game.ReplicatedStorage.Prefabs:WaitForChild("Objects");
local missionLibraryScript = game.ReplicatedStorage.Library.MissionLibrary;

local serverPrefabs = game.ServerStorage:WaitForChild("PrefabStorage"):WaitForChild("Objects");
local blockadeFolder = serverPrefabs:FindFirstChild("DefaultBlockades");

--== Script;
function OnPlayerAdded(player)
	local missionProfile; 
	repeat missionProfile = modMission.GetMissions(player.Name); until missionProfile ~= nil or not player:IsDescendantOf(game.Players) or not task.wait(0.5);
	if not player:IsDescendantOf(game.Players) then return end;
	
	local profile = shared.modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	
	if missionProfile == nil then return end;
	
	while not missionProfile.Loaded do
		task.wait(0.5);
		if not player:IsDescendantOf(game.Players) then
			break;
		end
	end
	if not player:IsDescendantOf(game.Players) then return end;
	
	local completedMissions = missionProfile:GetTypes(3);
	local repeatableMissionsUnlocked = false;
	for a=1, #completedMissions do
		local mission = completedMissions[a];
		local lib = modMissionLibrary.Get(mission.Id);
		if lib and lib.Rewards then
			for b=1, #lib.Rewards do
				if lib.Rewards[b].Type == "Mission" then
					
					local checkMission = missionProfile:Get(lib.Rewards[b].Id);
					if checkMission == nil then
						local reAddMission = missionProfile:Add(lib.Rewards[b].Id);
						Debugger:Log("Missing mission, adding ", lib.Rewards[b].Id, reAddMission);
					end
				end
			end
		end
		
		if mission.Id == 7 and modBranchConfigs.IsWorld("TheWarehouse") then
			local gateModel = workspace.Environment:FindFirstChild("BloxmartGate");
			if gateModel then
				gateModel:SetPrimaryPartCFrame(CFrame.new(286.61203, 69.4899445, 103.898018, 1, 0, 0, 0, 1, 0, 0, 0, 1));
			end
		end
		
		if mission.Id == 16 then
			repeatableMissionsUnlocked = true;
		end
		
		if mission.Id == 2 then
			profile:UnlockItemCodex("greytshirticyblue");
			profile:UnlockItemCodex("greytshirticyred");
		end
		
		if mission.Id == 3 then
			profile:UnlockItemCodex("oddbluebook");
		end

		if mission.Id == 4 then
			profile:UnlockItemCodex("zombiearm");
		end
		
		if mission.Id == 5 then
			profile:UnlockItemCodex("pistoldamagebp");
		end
		
		if mission.Id == 8 then
			profile:UnlockItemCodex("medkitbp");
		end
		
		if mission.Id == 9 then
			profile:UnlockItemCodex("incendiarybp");
		end

		if mission.Id == 10 then
			profile:UnlockItemCodex("antibiotics");
		end
		
		if mission.Id == 15 then
			profile:UnlockItemCodex("electricbp");
		end

		if mission.Id == 22 then
			profile:UnlockItemCodex("sewerskey1");
		end

		if mission.Id == 37 then
			profile:UnlockItemCodex("wateringcanbp");
		end
		
		if mission.Id == 41 then
			profile:UnlockItemCodex("cultistnote1");
		end

		if mission.Id == 50 then
			profile:UnlockItemCodex("bunnymanheadbenefactor");
		end
	end
	
	local activeMissions = missionProfile:GetTypes(1);
	for a=1, #activeMissions do
		local mission = activeMissions[a];
		if mission.Redo == true then continue end;
		
		local library = modMissionLibrary.Get(mission.Id);
		if library == nil or library.SkipDestroyIfAddRequirementsNotMet == true then
			continue 
		end;
		
		local canAdd, failReason = missionProfile:CanAdd(mission.Id, true);
		if not canAdd then
			Debugger:StudioWarn("Destroying mission (", mission ,") failAddReason: ", failReason);
			missionProfile:Destroy(mission);
		end
	end
	
	local mission5 = missionProfile:Get(5);
	if mission5 and (mission5.Type == 1 or mission5.Type == 3) then
		modBlueprints.UnlockBlueprint(player, "pistoldamagebp");
		modBlueprints.UnlockBlueprint(player, "pistolfireratebp", nil, false);
	end
	
	local mission8 = missionProfile:Get(8);
	if mission8 and (mission8.Type == 1 or mission8.Type == 3) then
		modBlueprints.UnlockBlueprint(player, "medkitbp");
	end
	
	local mission9 = missionProfile:Get(9);
	if mission9 and (mission9.Type == 1 or mission9.Type == 3) then
		modBlueprints.UnlockBlueprint(player, "incendiarybp");
	end
	
	local mission15 = missionProfile:Get(15);
	if mission15 and (mission15.Type == 1 or mission15.Type == 3) then
		modBlueprints.UnlockBlueprint(player, "electricbp");
	end
	
	local mission78 = missionProfile:Get(78);
	if mission78 == nil then
		local safehomeData = profile.Safehome;
		local npcData = safehomeData:GetNpc("Lydia");
		if npcData and ((npcData.Level or 0) >= 5) then
			missionProfile:Add(78);
		end
	end

	if modBranchConfigs.IsWorld("TheWarehouse") then
		local missionFirstRescue, _mIndex = missionProfile:Get(6);
		if missionFirstRescue == nil or missionFirstRescue.Type < 3 then
			
			local barricade = modReplicationManager.GetReplicated(player, "bloxmartBlockage")[1];
			if barricade == nil then
				Debugger:Warn("New barracade for "..player.Name);
				barricade = Prefabs:WaitForChild("bloxmartBlockage"):Clone();

				modReplicationManager.ReplicateIn(player, barricade, workspace.Environment);
			end
			
			local destructible = require(barricade:WaitForChild("Destructible"));
			destructible.NetworkOwners = {player};
			
			if missionFirstRescue then
				missionFirstRescue.Cache.Barricade = barricade;
				missionFirstRescue.Changed:Fire(false, missionFirstRescue);
				
			else
				
				missionProfile.OnMissionChanged:Connect(function(mission)
					if mission and mission.Id == 6 and mission.Type == 2 then 
						mission.Cache.Barricade = barricade;
					end
				end)
			end;
		end
		
		local missionFactoryRaid = missionProfile:Get(12);
		if missionFactoryRaid == nil or (missionFactoryRaid.Type < 3 and missionFactoryRaid.ProgressionPoint < 4) then

			Debugger:Warn("New factory blockade for "..player.Name);
			
			local blockade = blockadeFolder.BlockadeSingle:Clone();
			local hitbox = blockade:WaitForChild("Base"):Clone();
			hitbox.Size = Vector3.new(7, 11, 2);
			hitbox.CanCollide = true;
			hitbox.Parent = blockade;
			blockade.Name = "FactoryBlockade";
			blockade:PivotTo(CFrame.new(12.197, 60.155, 177.296) * CFrame.Angles(0, math.rad(90), 0));
			modReplicationManager.ReplicateIn(player, blockade, workspace.Environment);
			
			local destructibleObj = require(blockade:WaitForChild("Destructible"));
			destructibleObj.Enabled = false;
			destructibleObj.NetworkOwners = {player};
			
			if missionFactoryRaid then
				missionFactoryRaid.Cache.Blockade = blockade;
			else
				missionProfile.OnMissionChanged:Connect(function(mission)
					if mission and mission.Id == 12 and mission.Type == 2 then 
						mission.Cache.Blockade = blockade;
					end
				end)
			end
		end


		local jesseModule = modNpc.GetPlayerNpc(player, "Jesse");
		if jesseModule == nil then
			modReplicationManager.ReplicateOut(player, modNpc.Spawn("Jesse", nil, function(npc, npcModule)
				npcModule.Owner = player;
			end));
		end
		
	elseif modBranchConfigs.IsWorld("TheUnderground") then
		if modNpc.GetPlayerNpc(player, "Carlson") == nil then
			modReplicationManager.ReplicateOut(player, modNpc.Spawn("Carlson", nil, function(npc, npcModule)
				npcModule.Owner = player;
			end));
		end
		
		if modNpc.GetPlayerNpc(player, "Diana") == nil then
			modReplicationManager.ReplicateOut(player, modNpc.Spawn("Diana", nil, function(npc, npcModule)
				npcModule.Owner = player;
				task.delay(2, function()
					npcModule.PlayAnimation("leanforward");
				end)
			end));
		end
		
		if modNpc.GetPlayerNpc(player, "Erik") == nil then
			modReplicationManager.ReplicateOut(player, modNpc.Spawn("Erik", nil, function(npc, npcModule)
				npcModule.Owner = player;
			end));
		end

	elseif modBranchConfigs.IsWorld("TheResidentials") then
		
		local mission38 = missionProfile:Get(38); -- Something's Not Right
		local mission52 = missionProfile:Get(52); -- The Investigation

		if mission52.Type == 3 and mission38.Type == 1 and mission38.Redo ~= true then -- For some players softlocked with 52 completed.
			modMission:CompleteMission(player, 38);
		end

	end
	
	if repeatableMissionsUnlocked and activeSave then
		task.spawn(function()
			local doSync = false;
			while game.Players:IsAncestorOf(player) do
				if doSync then
					missionProfile:Sync();
					doSync = false;
				end
				
				task.wait(10);
				if not game.Players:IsAncestorOf(player) then return end;
				
				local unixTime = DateTime.now().UnixTimestamp;
				local missionIdsList = {};

				for _, mission in pairs(missionProfile) do
					if mission == nil then continue end;
					if mission.CatType ~= modMissionLibrary.MissionTypes.Board then continue end;
					if mission.Type ~= 3 then continue end;

					local isExpired = unixTime-(mission.CompletionTime or 0) >= modMissionLibrary.BoardMissionStockTimer;
					if isExpired then
						missionProfile:Destroy(mission);
						doSync = true;
					end
				end
				
				local templateMetaData = {Id="missionCycleData"; RepeatableMissionCount=0; LastAddUnixTime=0;};
				local missionMetaData = modEvents:GetEvent(player, "missionCycleData") or templateMetaData;
				
				local maxBoardMissions = 6;
				
				local timelaspedSinceLastAdd = unixTime - missionMetaData.LastAddUnixTime;
				local addCount = math.min(math.floor( (timelaspedSinceLastAdd) / modMissionLibrary.BoardMissionStockTimer ), maxBoardMissions);
				
				local availRepetablesMissions = 0;
				for _, missionData in pairs(missionProfile:GetCatTypes(modMissionLibrary.MissionTypes.Board)) do
					if missionData.Type == 2 then
						availRepetablesMissions = availRepetablesMissions +1;
					end
				end
				if availRepetablesMissions >= maxBoardMissions then
					missionMetaData.LastAddUnixTime = unixTime;
					modEvents:NewEvent(player, missionMetaData);
					
					continue;
				end;
				
				if availRepetablesMissions+addCount >= maxBoardMissions then
					addCount = maxBoardMissions-availRepetablesMissions;
				end
				
				if missionMetaData.LastAddUnixTime and addCount <= 0 then
					continue;
				end
				
				local maxPickFreq = 1;
				for id, missionLib in pairs(modMissionLibrary.List()) do
					if missionLib.MissionType ~= modMissionLibrary.MissionTypes.Board then continue end;
					table.insert(missionIdsList, missionLib);
					if missionLib.BoardPickFreq and missionLib.BoardPickFreq > maxPickFreq then
						maxPickFreq = missionLib.BoardPickFreq;
					end
				end

				repeat
					
					local pickableMissions = {};
					local fmodMissions = {};
					
					local fmod = math.fmod(missionMetaData.RepeatableMissionCount, maxPickFreq)+1;
					for a=1, #missionIdsList do
						local missionLib = missionIdsList[a];
						
						local missionId = missionLib.MissionId;
						local boardPickFreq = missionLib.BoardPickFreq or 1;
						
						if missionProfile:Get(missionId) == nil and missionProfile:CanAdd(missionId) then

							if boardPickFreq == 1 then
								table.insert(pickableMissions, missionLib.MissionId);
								
							elseif fmod == boardPickFreq then
								table.insert(fmodMissions, missionLib.MissionId);
								
							end
						end
					end
					
					local missionAdded = true;
					if #fmodMissions > 0 then
						local pickedId = fmodMissions[math.random(1, #fmodMissions)];
						modMission:AddMission(player, pickedId);
						Debugger:StudioWarn("New board mission ", pickedId);
						
					elseif #pickableMissions > 0 then
						local pickedId = pickableMissions[math.random(1, #pickableMissions)];
						modMission:AddMission(player, pickedId);
						Debugger:StudioWarn("New board mission ", pickedId);
						
					else
						missionAdded = false;
					end
					
					if missionAdded == false then break; end;
					
					addCount = addCount -1;

					missionMetaData.LastAddUnixTime = unixTime;
					missionMetaData.RepeatableMissionCount = missionMetaData.RepeatableMissionCount + 1;
					modEvents:NewEvent(player, missionMetaData);
					
				until addCount <= 0;
				
			end
		end)
	end
	
	--if dailyMissionsUnlocked and activeSave then
	--	local activeDailyMissionId = activeSave.ActiveDailyMissionId;
	--	local activeDailyMission = missionProfile:Get(activeDailyMissionId);
		
	--	if activeDailyMission == nil then
	--		local libDailyMissions = {};
			
	--		local survivorMission = false;
	--		for id, missionLib in pairs(modMissionLibrary.List()) do
	--			if missionLib.MissionType == modMissionLibrary.MissionTypes.Board and missionProfile:CanAdd(id) then
	--				if id == 55 then
	--					survivorMission = true;
	--				end
	--				table.insert(libDailyMissions, id);
	--			end
	--		end
			
	--		local randomPickId;
			
	--		if survivorMission and math.fmod(os.date("%j"), 2) == 0 then
	--			randomPickId = 55;
	--		else
	--			local roll = modPseudoRandom:NextInteger(player, "DailyMission", 1, #libDailyMissions);
	--			randomPickId = libDailyMissions[roll];
	--		end
			
	--		activeSave.ActiveDailyMissionId = randomPickId;
	--		modMission:AddMission(player, randomPickId);
	--	end
	--end

	local cache = {};
	
	for a=1, #missionProfile do
		local mission = missionProfile[a];
		local missionLib = modMissionLibrary.Get(mission.Id);
		

		if missionLib.AddCache then
			for k,v in pairs(missionLib.AddCache) do
				cache[k] = v;
			end
		end
		
		local missionLogic = missionLibraryScript:FindFirstChild(missionLib.Name);
		if missionLogic then
			local modMissionFunctions = require(missionLogic);

			if modMissionFunctions and modMissionFunctions.Init then
				task.spawn(function()
					modMissionFunctions.Init(missionProfile, mission);
				end)
			end
		end 
	end

	modEvents:NewEvent(player, {Id="MissionCache"; Value=cache;});

end

remoteProgressMission.OnServerEvent:Connect(function(player, missionId, ...)
	if not modMission:IsComplete(player, 27) then
		local progressionPoint = ...;
		
		if progressionPoint == 1 then
			modMission:Progress(player, 27, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.ProgressionPoint = 2;
				end;
			end)
		end
	end
end)

local modEngineCore = require(game.ReplicatedStorage.EngineCore);
modEngineCore:ConnectOnPlayerAdded(script, OnPlayerAdded);

