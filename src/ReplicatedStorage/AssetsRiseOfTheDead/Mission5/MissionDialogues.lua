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
Dialogues.Mason.Dialogues = function()
	return {
		{Tag="timeToUpgrade_upgrade?";
			Face="Happy"; Reply="Have you upgraded your pistol yet?";};

		{Tag="timeToUpgrade_request"; CheckMission=missionId; Dialogue="Can you teach me how to upgrade my weapons?"; 
			Face="Happy"; Reply="Sure, you can upgrade your weapon at the workbench."};
		{Tag="timeToUpgrade_how1"; Dialogue="What should I do?"; 
			Face="Confident"; Reply="Build yourself a Pistol Damage Mod from the workbench. Then, equip the mod onto your gun and upgrade it."};
		{Tag="timeToUpgrade_how2"; Dialogue="How do I get the resources to build a Pistol Damage Mod?"; 
			Face="Confident"; Reply="Some zombies will drop some money and metal items when you kill them, those are useful for building stuff."};
	};
end

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
			dialog:SetInitiateTag("timeToUpgrade_upgrade?");
			dialog:AddChoice("timeToUpgrade_how1");
			dialog:AddChoice("timeToUpgrade_how2");
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;