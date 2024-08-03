local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Mason={};
};

local missionId = 5;
--==

-- !outline: Mason Dialogues
Dialogues.Mason.DialogueStrings = {
	["timeToUpgrade_upgrade"]={
		Face="Happy"; 
		Reply="Have you upgraded your pistol yet?";
	};

	["timeToUpgrade_request"]={
		CheckMission=missionId;
		Say="Can you teach me how to upgrade my weapons?"; 
		Face="Happy"; 
		Reply="Sure, you can upgrade your weapon at the workbench.";
	};
	["timeToUpgrade_how1"]={
		Say="What should I do?"; 
		Face="Confident"; 
		Reply="Build yourself a Pistol Damage Mod from the workbench. Then, equip the mod onto your gun and upgrade it.";
	};
	["timeToUpgrade_how2"]={
		Say="How do I get the resources to build a Pistol Damage Mod?"; 
		Face="Confident"; 
		Reply="Some zombies will drop some money and metal items when you kill them, those are useful for building stuff.";
	};
};

if RunService:IsServer() then
	
	-- !outline: Mason Handler
	Dialogues.Mason.DialogueHandler = function(player, dialog, data, mission)
		local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		local modAnalyticsService = require(game.ServerScriptService.ServerLibrary.AnalyticsService);

		if mission.Type == 2 then -- Available;
			dialog:AddChoice("timeToUpgrade_request", function(dialog)
				modMission:StartMission(player, missionId, function(successful)
					if successful then
						modBlueprints.UnlockBlueprint(player, "pistoldamagebp");
						
						modAnalyticsService:LogOnBoarding{
							Player=player;
							OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission5_Start;
						};

					end
				end);
			end);
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiateTag("timeToUpgrade_upgrade");
			dialog:AddChoice("timeToUpgrade_how1");
			dialog:AddChoice("timeToUpgrade_how2");
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;