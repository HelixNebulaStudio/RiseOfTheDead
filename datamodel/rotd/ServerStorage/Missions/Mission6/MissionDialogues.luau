local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Robert={};
};

local MISSION_ID = 6;
--==

-- !outline: Robert Dialogues
Dialogues.Robert.DialogueStrings = {		
	["firstRescue_how"]={
		CheckMission=MISSION_ID;
		Say="How can I get you out?!"; 
		Face="Worried"; 
		Reply="Ummmm, try destroying this wooden barricade.";
		FailResponses = {
			{Reply="I think you're going need to bring some better tools to destroy this barricade."};
		};
	};
	["firstRescue_standback"]={
		Say="Alright, stand back."; 
		Face="Surprise"; 
		Reply="Hope this works...";
	};
};

if RunService:IsServer() then
	-- !outline: Robert Handler
	Dialogues.Robert.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("Help!! I'm trapped!");
			dialog:AddChoice("firstRescue_how", function(dialog)
				dialog:AddChoice("firstRescue_standback", function(dialog)
					modMission:StartMission(player, MISSION_ID);
					modAnalyticsService:LogOnBoarding{
						Player=player;
						OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission6_Start;
					};
					
				end)
			end);
			
		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:SetInitiate("The barricade is almost destroyed..");

			elseif mission.ProgressionPoint == 2 then
				dialog:SetInitiate("Please take me somewhere safe.");
				
			end
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;