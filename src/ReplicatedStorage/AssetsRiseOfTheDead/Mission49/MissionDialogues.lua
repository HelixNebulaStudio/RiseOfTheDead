local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Mason={};
};

local missionId = 49;
--==

-- !outline: Mason Dialogues
Dialogues.Mason.Dialogues = function()
	return {
		{Tag="navigation_sure"; Dialogue="Sure, what do you need?";
			Face="Welp"; Reply="I left a book somewhere while scavenging. I was out of space so I had to leave it, I need you to look for it."};
		{Tag="navigation_where"; Dialogue="Oh alright, where is it?"; 
			Face="Confident"; Reply="It should be in the abandon office beside the bank. I think you should buy a GPS from the shop to navigate there.\n\nBe careful on your way!"};
		{Tag="navigation_done"; Dialogue="I found it, the Vehicle Repair Manual.";
			Face="Frustrated"; Reply="YES! That's the one..\n*reads book*\nHmmm, well I'll be ####ed, I have no clue where to find these components to fix the car.."};

	};
end

if RunService:IsServer() then
	-- !outline: Mason Handler
	Dialogues.Mason.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("Ugh, what am I missing.. I have been trying to repair this car for so long, I can't seem to figure out what it's missing. Hey, $PlayerName, can you lend a hand?", "Skeptical");
			dialog:AddChoice("navigation_sure", function(dialog)
				dialog:AddChoice("navigation_where", function(dialog)
					modMission:StartMission(player, missionId);
				end);
			end);
			
		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 5 then
				dialog:AddChoice("navigation_done", function(dialog)
					modMission:CompleteMission(player, missionId);
				end)

			else
				dialog:SetInitiate("You ran into some trouble?", "Skeptical");
			end
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;