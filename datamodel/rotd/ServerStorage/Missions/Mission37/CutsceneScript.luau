local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

--== Variables;
local MISSION_ID = 37;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modDialogues = shared.require(game.ServerScriptService.ServerLibrary.DialogueSave);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);

	if modBranchConfigurations.IsWorld("TheResidentials") or modBranchConfigurations.IsWorld("BioXResearch") then
		shared.modEventService:OnInvoked("Farming_BindWaterPlanter", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local data = ...;
			
			task.spawn(function()
				if data.NewWater < 100 then return end;

				local objKeys = {"jlLettuce1"; "jlLettuce2"; "jlLettuce3"};
				local mission: Mission = modMission:GetMission(player, MISSION_ID);

				for a=1, #objKeys do
					local objKey = objKeys[a];
					if mission.ObjectivesCompleted[objKey] then continue end;

					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ObjectivesCompleted[objKey] = true;
					end)
					
					break;
				end
			end)
		end)
	end


else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigurations.IsWorld("TheResidentials") then 
		Debugger:Warn("Invalid place for cutscene ("..script.Name..")");
		return;
	end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
				
		local function OnChanged(firstRun)
			if mission.Type == 3 then
				mission.OnChanged:Disconnect(OnChanged);
			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;