local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Rachel={};
};

local missionId = 75;
--==

-- !outline: Rachel Dialogues
Dialogues.Rachel.Dialogues = function()
	return {
		{Tag="medbre_init";
			Face="Worried"; Reply="Stan saved my life, I was trapped and he heard me cried for help. I miss him so much..";};

		{CheckMission=missionId; Tag="medbre_start"; Dialogue="Hey, it's okay. I have some news about Stan.";
			Face="Worried"; Reply="News.. about Stan?";
			FailResponses = {
				{Reply="Hold on, I'm quite busy right now.."};
			};	
		};
		{Tag="medbre_start2"; Dialogue="Yes, so apparently Stan is still alive.";
			Face="Disbelief"; Reply="..."};
	};
end

if RunService:IsServer() then
	-- !outline: Rachel Handler
	Dialogues.Rachel.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiateTag("medbre_init");

			dialog:AddChoice("medbre_start", function(dialog)
				modMission:StartMission(player, missionId);
				
				modMission:CompleteMission(player, 75);
				
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint <= 1 then
						mission.ProgressionPoint = 1;
					end
				end);
			end)
			
			
		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				
			end
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;