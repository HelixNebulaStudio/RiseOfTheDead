local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Joseph={};
};

local MISSION_ID = 37;
--==

-- MARK: Joseph Dialogues
Dialogues.Joseph.DialogueStrings = {
	["josephsLettuce_start"]={
		CheckMission=MISSION_ID;
		Face="Joyful";
		Say="Sure, how do I help make the watering can?"; 
		Reply="Here's a blueprint, after you're done please also water the plants for me.";
	};
	["josephsLettuce_end"]={
		Face="Happy";
		Say="Yep, I watered them."; 
		Reply="Good job, get some rest. You earned it.";
	};
		
};


if RunService:IsServer() then
	-- MARK: Joseph Handler
	Dialogues.Joseph.DialogueHandler = function(player, dialog, data, mission)
		local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local modBlueprints = shared.require(game.ServerScriptService.ServerLibrary.Blueprints);

		if modBranchConfigurations.IsWorld("TheInvestigation") then return end;

		if mission.Type == 1 then -- Active
			dialog:SetInitiate("You got it done?");
			if mission.ObjectivesCompleted["wateringcan"] == true
			or mission.ObjectivesCompleted["jlLettuce1"] == true
			or mission.ObjectivesCompleted["jlLettuce2"] == true
			or mission.ObjectivesCompleted["jlLettuce3"] == true then
				dialog:AddChoice("josephsLettuce_end", function(dialog)
					modMission:CompleteMission(player, MISSION_ID);
				end)
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("Ooh Howdy partner, my old watering can broke, do you mind helping me out?");
			dialog:AddChoice("josephsLettuce_start", function(dialog)
				modMission:StartMission(player, MISSION_ID, function(successful)
					if successful then
						modBlueprints.UnlockBlueprint(player, "wateringcanbp");
					end
				end);
			end)
			
		end
	end
end


return Dialogues;