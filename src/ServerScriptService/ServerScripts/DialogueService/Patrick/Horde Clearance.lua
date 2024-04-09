local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

--==
return function(player, dialog, data, mission)
	if mission.Type == 2 then -- Available
		
	elseif mission.Type == 1 then -- Active
		if mission.ProgressionPoint == 2 then
			local profile = shared.modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			
			local dialogPacket = {
				Face="Happy";
				Dialogue="I've done killing the horde..";
				Reply="Wow, you better wash the blood off your clothes.";
				MissionId=59;
			};
			
			dialog:AddDialog(dialogPacket, function(dialog)
				modMission:CompleteMission(player, 59);
			end)
		end
		
	end
end
