local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Mason={};
};

local missionId = 27;
--==

-- !outline: Mason Dialogues
Dialogues.Mason.Dialogues = function()
	return {
		--{Tag="medbre_init";
		--	Face="Worried"; Reply="Stan saved my life, I was trapped and he heard me cried for help. I miss him so much..";};

		--{CheckMission=missionId; Tag="medbre_start"; Dialogue="Hey, it's okay. I have some news about Stan.";
		--	Face="Worried"; Reply="News.. about Stan?";
		--	FailResponses = {
		--		{Reply="Hold on, I'm quite busy right now.."};
		--	};	
		--};
		--{Tag="medbre_start2"; Dialogue="Yes, so apparently Stan is still alive.";
		--	Face="Disbelief"; Reply="..."};
		
		{Tag="focusLevels_request"; Dialogue="Which specific zombies?";
			Face="Happy"; Reply="Here's a list of zombies, I labelled some with different levels because some seems to be stronger than others.."};
		{Tag="focusLevels_okay"; Dialogue="So I have to focus on specific levels of zombies?";
			Face="Joyful"; Reply="Exactly! The perks of focusing them is that you will get to improve your weapons based on how strong they are.\n\nGood luck out there."};

	};
end

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
