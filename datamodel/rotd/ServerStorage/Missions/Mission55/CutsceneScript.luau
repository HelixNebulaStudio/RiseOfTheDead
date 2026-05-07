local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
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
	modSafehomeService = shared.require(game.ServerScriptService.ServerLibrary.SafehomeService);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if shared.WorldName ~= "Safehome" then
		Debugger:Warn(`Invalid place for cutscene ({script.Name})`);
		return;
	end;

	local spawnCf = CFrame.new(109.12, 2.55, -79.31) * CFrame.Angles(0, math.pi/2, 0);
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local profile = shared.modProfile:Get(player);
		local safehomeData = profile.Safehome;
		Debugger:WarnClient(player, `AnotherSurvivor>>  Loading Cutscene..`);

		local safehomeClass = shared.WorldCore.SafehomeClass;
		local lc = 0;
		while safehomeClass == nil and game.Players:IsAncestorOf(player) do
			safehomeClass = shared.WorldCore.SafehomeClass;
			task.wait(1);
			lc += 1;
			if lc > 30 then
				Debugger:WarnClient(player, `AnotherSurvivor>>  Still waiting for cutscene to load ({lc})..`);
			end
		end
		if safehomeClass.FactionTag then 
			Debugger:WarnClient(player, "AnotherSurvivor>>  Mission skipped in faction hq.");
			return
		end;
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
			elseif mission.Type == 1 then -- OnActive
				if firstRun then
				end
				
				if mission.ProgressionPoint == 1 then
					local newNpcName;

					local wantedPoster = modEvents:GetEvent(player, "wantedPoster");
					Debugger:WarnClient(player, "AnotherSurvivor>>  wantedPoster", wantedPoster);

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

							local rCount = 0;
							repeat
								rewards = modDropRateCalculator.RollDrop(rewardsList, player);
								newNpcName = rewards[1].Name;
								task.wait();
								rCount += 1;
								if (rCount)%1000 then
									Debugger:WarnClient(player, "AnotherSurvivor>>  Rolling a survivor NpcName...");
								end
							until safehomeData.Npc[newNpcName] == nil or safehomeData.Npc[newNpcName].Active == nil;
						end
					end

					if mission.SaveData.NpcName then
						newNpcName = mission.SaveData.NpcName;
					end
					mission.SaveData.NpcName = newNpcName;

					local arriveStr = `AnotherSurvivor>>  A survivor, {newNpcName}, has arrived to your safehome..`;
					shared.Notify(player, arriveStr, "Inform");
					Debugger:WarnClient(player, arriveStr);
					
					local survivorNpcClass: NpcClass = modNpcs.getPlayerNpc(player, newNpcName);

					if survivorNpcClass == nil or survivorNpcClass.HealthComp.IsDead then
						survivorNpcClass = modNpcs.spawn2{
							Name = newNpcName;
							CFrame = spawnCf;
							Player = player;
						};
							
						Debugger:WarnClient(player, `AnotherSurvivor>>  Spawning survivor.`);
					end

					survivorNpcClass:SetCFrame(spawnCf);

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