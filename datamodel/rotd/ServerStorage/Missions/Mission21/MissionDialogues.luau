local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Jane={};
};

local MISSION_ID = 21;
--==

-- MARK: Jane Dialogues
Dialogues.Jane.DialogueStrings = {
	["springkill_yes"]={
		CheckMission=MISSION_ID;
		Say="Yes, I'm up for it.";
		Face="Happy"; 
		Reply="Bloxmart, the bank and the factory. You know the places..";
	};
	["springkill_done"]={
		Say="I've killed them all."; 
		Face="Joyful"; 
		Reply="Hurray! I feel much safer already..";
	};
	["springkill_notYet"]={
		Say="Still On it.."; 
		Face="Excited"; 
		Reply="Good luck~";
	};
};

if RunService:IsServer() then
	-- MARK: Jane Handler
	Dialogues.Jane.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			dialog:SetInitiate("How's the progress, $PlayerName?");
			
			if mission.ObjectivesCompleted["The Prisoner"] == true
			and mission.ObjectivesCompleted["Tanker"] == true
			and mission.ObjectivesCompleted["Fumes"] == true then
				dialog:AddChoice("springkill_done", function(dialog)
					modMission:CompleteMission(player, MISSION_ID);
				end)
			else
				dialog:AddChoice("springkill_notYet");
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("Hey, you up for some killing?");
			dialog:AddChoice("springkill_yes", function(dialog)
				modMission:StartMission(player, MISSION_ID);
			end)
			
		end
	end
end


return Dialogues;