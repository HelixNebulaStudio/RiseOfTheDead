local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Mason={};
};

local missionId = 27;
--==

-- !outline: Mason DialogueStrings
Dialogues.Mason.DialogueStrings = {
	["focusLevels_request"]={
		Face="Happy";
		Say="Which specific zombies?";
		Reply="Here's a list of zombies, I labelled some with different levels because some seems to be stronger than others..";
	};
	["focusLevels_okay"]={
		Face="Joyful";
		Say="So I have to focus on specific levels of zombies?";
		Reply="Exactly! The perks of focusing them is that you will get to improve your weapons based on how strong they are.\n\nGood luck out there.";
	}
};

if RunService:IsServer() then
	-- !outline: Mason Handler
	Dialogues.Mason.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("$PlayerName, you are one top notch zombie killer and I need your help on killing some specific zombie.");
			dialog:AddChoice("focusLevels_request", function(dialog)
				dialog:AddChoice("focusLevels_okay", function(dialog)
					modMission:StartMission(player, missionId);
				end)
			end)
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiate("Remember, on the list I gave you, if it says \"L2: 20\" means kill 20 level 2 zombies.");

		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;