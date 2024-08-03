local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Patrick={};
};

local missionId = 61;
--==

-- MARK: Patrick Dialogues
Dialogues.Patrick.DialogueStrings = {};

if RunService:IsServer() then
	-- MARK: Patrick Handler
	Dialogues.Patrick.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		local profile = shared.modProfile:Get(player);
		local playerSave = profile:GetActiveSave();
		
		if mission.Type == 1 then -- Active
			dialog:SetInitiate("We're gonna need more ammunition to sustain our defense..", "Serious");
			
			local inventory = playerSave.Inventory;
			local total, itemList = inventory:ListQuantity("ammobox", 1);
			if total >= 1 then
				local dialogPacket = {
					Face="Happy";
					Say="Here's a box of ammo.";
					Reply="Great, that'll do.";
					MissionId=missionId;
				};
	
				dialog:AddDialog(dialogPacket, function(dialog)
					for a=1, #itemList do
						inventory:Remove(itemList[a].ID, itemList[a].Quantity);
						shared.Notify(player, "Ammo Box removed from your Inventory.", "Negative");
					end
					
					modMission:CompleteMission(player, missionId);
				end)
			end
			
			
		end
	end
end


return Dialogues;