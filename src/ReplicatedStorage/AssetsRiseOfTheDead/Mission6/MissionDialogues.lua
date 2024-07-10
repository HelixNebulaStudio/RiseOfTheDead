local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Robert={};
};

local missionId = 6;
--==

-- !outline: Robert Dialogues
Dialogues.Robert.Dialogues = function()
	return {		
		{Tag="firstRescue_how"; CheckMission=missionId; Dialogue="How can I get you out?!"; 
			Face="Worried"; Reply="Ummmm, try destroying this wooden barricade.";
			FailResponses = {
				{Reply="I think you're going need to bring some better tools to destroy this barricade."};
			};
		};
		{Tag="firstRescue_standback"; Dialogue="Alright, stand back."; 
			Face="Surprise"; Reply="Hope this works..."};
	};
end

if RunService:IsServer() then
	-- !outline: Robert Handler
	Dialogues.Robert.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		local modAnalyticsService = require(game.ServerScriptService.ServerLibrary.AnalyticsService);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("Help!! I'm trapped!");
			dialog:AddChoice("firstRescue_how", function(dialog)
				dialog:AddChoice("firstRescue_standback", function(dialog)
					modMission:StartMission(player, missionId);
					modAnalyticsService:LogOnBoarding{
						Player=player;
						OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission6_Start;
					};
					
				end)
			end);
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiate("Please take me somewhere safe.");
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;