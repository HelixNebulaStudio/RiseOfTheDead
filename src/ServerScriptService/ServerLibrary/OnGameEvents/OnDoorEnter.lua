local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);

local remotes = game.ReplicatedStorage.Remotes;
local bindOnDoorEnter = remotes.Interactable.OnDoorEnter;

--== When a player enters a door;
return function(player, interactData)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local inventory = activeSave and activeSave.Inventory;
	
	if interactData.Object and interactData.Object:FindFirstChild("Destination") then
		local destination = interactData.Object.Destination;
		profile.LastDoorCFrame = CFrame.new(destination.WorldPosition + Vector3.new(0, 2.35, 0)) * CFrame.Angles(0, math.rad(destination.WorldOrientation.Y-90), 0);
	end
	
	if interactData.SetSpawn and activeSave then
		activeSave.Spawn = interactData.SetSpawn;
	end
		
	local doorName = interactData.Name;
	if doorName == "Warehouse Entrance Door" then
		if modMission:Progress(player, 12) and modMission:Progress(player, 12).ProgressionPoint >= 5 then
			modMission:CompleteMission(player, 12);
		end
		
	elseif doorName == "Security Entrance Door" then
		modMission:Progress(player, 7, function(mission)
			if mission.ProgressionPoint == 4 then mission.ProgressionPoint = 5; end;
		end)
		
	elseif doorName == "Security Exit Door" then
		modMission:Progress(player, 7, function(mission)
			if mission.ProgressionPoint == 6 then mission.ProgressionPoint = 7; end;
		end)
		
	elseif doorName == "Sundays Entrance" then
		if modMission:Progress(player, 7) and modMission:Progress(player, 7).ProgressionPoint == 7 then
			modMission:CompleteMission(player, 7);
		end;
		modMission:Progress(player, 14, function(mission) if mission.ProgressionPoint < 2 then mission.ProgressionPoint = 2; end; end)
		
	elseif doorName == "Underbridge Entrance Door" then
		modMission:Progress(player, 18, function(mission)
			if mission.ProgressionPoint <= 5 then mission.ProgressionPoint = 6; end;
		end)
	
	elseif doorName == "SewersMaintenanceRoom" then
		modMission:Progress(player, 22, function(mission)
			if mission.ProgressionPoint == 2 then mission.ProgressionPoint = 3; end;
		end)
		
	elseif doorName == "Sh3Shortcut" then
		if modEvents:GetEvent(player, "sh3Shortcut") == nil then
			modEvents:NewEvent(player, {Id="sh3Shortcut"});
		end
		
	elseif doorName == "easterDoor1" then
		modStatusEffects.Dizzy(player, 10);
		modMission:Progress(player, 32, function(mission)
			if mission.ProgressionPoint == 2 then mission.ProgressionPoint = 3; end;
		end)
			
	elseif doorName == "BanditCampThroneDoor" then
		modMission:Progress(player, 33, function(mission)
			if mission.ProgressionPoint < 6 then mission.ProgressionPoint = 6; end;
		end)
		
	elseif doorName == "BanditOutpostRoom" then
		modMission:Progress(player, 33, function(mission)
			if mission.ProgressionPoint == 13 then mission.ProgressionPoint = 14; end;
		end)
		
	elseif doorName == "VT Cave Exit" then
		modMission:Progress(player, 42, function(mission)
			if mission.ProgressionPoint == 6 then mission.ProgressionPoint = 7; end;
		end)

	elseif doorName == "eb2Door" then
		modMission:Progress(player, 50, function(mission)
			if mission.ProgressionPoint == 3 then mission.ProgressionPoint = 4; end;
		end)
		

	elseif doorName == "RadioRoofDoor" then
		modMission:Progress(player, 51, function(mission)
			if mission.ProgressionPoint == 2 then mission.ProgressionPoint = 3; end;
		end)
		
	elseif doorName == "ResidentialBasementDoor" then
		modMission:Progress(player, 56, function(mission)
			if mission.ProgressionPoint == 1 then mission.ProgressionPoint = 2; end;
		end)
		
	end
	
	if interactData.EscortMission then
		local mission = modMission:GetMission(player, 34);
		if mission and mission.SaveData and mission.SaveData.Location == interactData.EscortMission then
			modMission:Progress(player, 34, function(mission)
				if mission.ProgressionPoint == 2 then mission.ProgressionPoint = 3; end;
			end)
		end
	end
	
	if interactData.SetSpawn then
		modMission:Progress(player, 48, function(mission)
			if mission.ProgressionPoint >= 2 then 
				modMission:CompleteMission(player, 48);
			end
		end)
		
		if interactData.SetSpawn == "hacClinic1" then
			modMission:Progress(player, 52, function(mission)
				if mission.ProgressionPoint == 15 then mission.ProgressionPoint = 16; end;
			end)
		end
	end
	
	bindOnDoorEnter:Fire(player, interactData);
end;
