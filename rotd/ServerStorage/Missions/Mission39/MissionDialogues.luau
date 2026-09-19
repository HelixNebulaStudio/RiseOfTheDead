local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Danny={};
};

local MISSION_ID = 39;
--==

-- MARK: Danny Dialogues
Dialogues.Danny.DialogueStrings = {
	["spikingUp_start"]={
		CheckMission=MISSION_ID;
		Face="Skeptical";
		Say="Sure, what do you need?";
		Reply="The zombies are often walking into the store gate and causing a lot of noise, could you build something to prevent that?";
	};

	["spikingUp_sure"]={
		Face="Surprise";
		Say="How about some wooden spikes on the gates?";
		Reply="Yeah! That's what I had in mind.";
	};
	
	["spikingUp_complete"]={
		Face="Confident";
		Say="Yeah, it done. Hope you like it."; 
		Reply="Great, now I can eat my beans in peace.";
	};
	
};

if RunService:IsServer() then
	-- MARK: Danny Handler
	Dialogues.Danny.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			dialog:SetInitiate("How's it going?", "Confident");
			
			if mission.ObjectivesCompleted["addWall1"]
			and mission.ObjectivesCompleted["addWall2"]
			and mission.ObjectivesCompleted["addWall3"]
			and mission.ObjectivesCompleted["addWall4"]
			and mission.ObjectivesCompleted["addWall5"] then
				dialog:AddChoice("spikingUp_complete", function(dialog)
					modMission:CompleteMission(player, MISSION_ID);
				end)
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("Hey, could you do me a favor?");
			
			dialog:AddChoice("spikingUp_start", function(dialog)
				dialog:AddChoice("spikingUp_sure", function(dialog)
					modMission:StartMission(player, MISSION_ID);
				end)
			end)
		
		elseif mission.Type == 3 then -- Complete
			
		end
	end
end


return Dialogues;