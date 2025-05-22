local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modDropRateCalculator = shared.require(game.ReplicatedStorage.Library.DropRateCalculator);

--== Variables;
local MISSION_ID = 55;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("Safehome") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	if workspace:GetAttribute("FactionHeadquarters") ~= nil then Debugger:Warn("Is faction world"); return end;

	local spawnCf = CFrame.new(109.12, 2.55, -79.31) * CFrame.Angles(0, math.pi/2, 0);
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		while not shared.modSafehomeService.MapLoaded do wait(1); end
		while modServerManager.PrivateWorldCreator == nil do wait(1); end
		
		if modServerManager.PrivateWorldCreator ~= player then return end;
		
		local profile = shared.modProfile:Get(player);
		local safehomeData = profile.Safehome;
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
			elseif mission.Type == 1 then -- OnActive
				if firstRun then
				end
				
				if mission.ProgressionPoint == 1 then
					local newNpcName;

					local wantedPoster = modEvents:GetEvent(player, "wantedPoster");
					Debugger:WarnClient(player, "wantedPoster", wantedPoster);

					if wantedPoster then
						newNpcName = wantedPoster.Name;

						if safehomeData.Npc[newNpcName] and safehomeData.Npc[newNpcName].Active then
							newNpcName = nil;
						end
					end

					if newNpcName == nil then
						local eventPacket = modEvents:GetEvent(player, "firstNpcRoll");
						if eventPacket == nil then
							local rewardsList = modRewardsLibrary:Find("safehomeMedic");
							local rewards = modDropRateCalculator.RollDrop(rewardsList, player);

							newNpcName = rewards[1].Name;
							modEvents:NewEvent(player, {Id="firstNpcRoll"; Name=newNpcName;});
						else
							local rewardsList = modRewardsLibrary:Find("safehomeNpcs");
							local rewards;

							repeat
								rewards = modDropRateCalculator.RollDrop(rewardsList, player);
								newNpcName = rewards[1].Name;
								task.wait();
							until safehomeData.Npc[newNpcName] == nil or safehomeData.Npc[newNpcName].Active == nil;
						end
					end

					if mission.SaveData.NpcName then
						newNpcName = mission.SaveData.NpcName;
					end
					mission.SaveData.NpcName = newNpcName;

					Debugger:Warn("Chosen NPC:", newNpcName, " mission.SaveData.NpcName", mission.SaveData.NpcName);
					local survivorNpcModule = modNpcs.getByOwner(player, newNpcName);

					if survivorNpcModule == nil then
						modNpcs.spawn(newNpcName, spawnCf, function(npc, npcModule)
							npcModule.Owner = player;
							survivorNpcModule = npcModule;
						end);
					end

					survivorNpcModule:Teleport(spawnCf);

					task.spawn(function()
						local remotes = game.ReplicatedStorage.Remotes;
						local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");
						remoteSetHeadIcon:FireAllClients(0, newNpcName, "HideAll");
						remoteSetHeadIcon:FireAllClients(1, newNpcName, "Mission");
					end)
					
					
				elseif mission.ProgressionPoint == 2 then
					
				end
				
			elseif mission.Type == 3 then -- OnComplete
				modEvents:RemoveEvent(player, "wantedPoster");
				
			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;