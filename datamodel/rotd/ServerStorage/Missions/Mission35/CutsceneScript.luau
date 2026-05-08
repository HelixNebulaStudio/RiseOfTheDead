local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

--== Variables;
local MISSION_ID = 35;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if modGameModeManager.GameWorld ~= true and not RunService:IsStudio() then
		Debugger:Warn("Invalid place for cutscene ("..script.Name..")");
		return; 
	end;
	
	shared.modEventService:OnInvoked("GameModeManager_BindGameModeStart", function(eventPacket: EventPacket, packet)
		local room = packet.Room;
		if room.Type ~= "Raid" then return end;
		if eventPacket.Players == nil then return end;
		
		for _, player: Player in pairs(eventPacket.Players) do
			if not modMission:Progress(player, MISSION_ID) then continue end;

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.ProgressionPoint = 2;

					local curTime = workspace:GetServerTimeNow();
					mission.SaveData.StartTime = curTime;
				end
			end)

		end
	end)
	
	shared.modEventService:OnInvoked("GameModeManager_BindGameModeComplete", function(eventPacket: EventPacket, packet)
		local room = packet.Room;

		if room.Type ~= "Raid" then return end;
		if eventPacket.Players == nil then return end;
		
		for _, player: Player in pairs(eventPacket.Players) do
			if not modMission:Progress(player, MISSION_ID) then continue end;

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint < 3 then
					mission.ProgressionPoint = 3;
				end
			end)
		end
	end)
	
	shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
		local triggerPlayer: Player? = event.Player;
		if triggerPlayer == nil then return end;

		local id: string, interactable: InteractableInstance = ...;

		task.spawn(function()
			if id == "mission35FoodScavenge" then
				
				for _, player in pairs(game.Players:GetPlayers()) do
					shared.Notify(player, triggerPlayer.Name .." has successfully extracted the food package.", "Reward");
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 3 then
							local curTime = workspace:GetServerTimeNow();

							local timer = mission.SaveData.Timers.T1;
							if timer == nil then
								timer = {StartTime=curTime-299;};
							end

							mission.SaveData.FactionData = {
								Timelapsed = curTime - timer.StartTime;
							}
							modMission:CompleteMission(player, MISSION_ID);
						end
					end)
				end
				Debugger.Expire(interactable.Part.Parent, 0);
			end
		end)
	end)

	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		Debugger:Log("mission.SaveData", mission.SaveData);
		if shared.WorldName ~= mission.SaveData.Location and not RunService:IsStudio() then 
			Debugger:Log("Wrong world");
			return;
		end;

		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then

				elseif mission.ProgressionPoint == 2 then
					if mission.SaveData.Timers == nil then
						mission.SaveData.Timers = {};
					end
					if mission.SaveData.Timers.T1 == nil then
						mission.SaveData.Timers.T1 = {
							FailOnTimeout = true;
							Duration = 300;
							StartTime = workspace:GetServerTimeNow();
							DefaultText = "Time until air drop is stolen..";
							TimeoutText = "Air drop has been stolen by another faction!";
						};
					end

				elseif mission.ProgressionPoint == 3 then
					local newCrate = game.ServerStorage.Prefabs.Objects.Crates.CratePallet:Clone();
					newCrate.Name = "FoodScavengePackage";

					local newInteractConfig = modInteractables.createInteractable("ButtonRotd");
					newInteractConfig:SetAttribute("_InteractDuration", 3);
					newInteractConfig:SetAttribute("_Id", "mission35FoodScavenge");
					newInteractConfig:SetAttribute("_Label", "Extract Food Package");
					newInteractConfig.Parent = newCrate;
					
					newCrate:PivotTo(workspace:FindFirstChild("RewardSpawn", true).CFrame * CFrame.new(0, 2, 0));
					newCrate.Parent = workspace.Interactables;
					
					Debugger:Log("Spawn food package ", newCrate:GetPivot().Position);
					
				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;