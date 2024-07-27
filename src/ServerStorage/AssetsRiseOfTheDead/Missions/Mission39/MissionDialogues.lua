local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Danny={};
};

local missionId = 39;
--==

-- MARK: Danny Dialogues
Dialogues.Danny.Dialogues = function()
	return {
		{CheckMission=missionId; Tag="spikingUp_start"; Face="Skeptical";
			Dialogue="Sure, what do you need?";
			Reply="The zombies are often walking into the store gate and causing a lot of noise, could you build something to prevent that?"};

		{Tag="spikingUp_sure"; Face="Surprise";
			Dialogue="How about some wooden spikes on the gates?";
			Reply="Yeah! That's what I had in mind."};
		
		{Tag="spikingUp_complete"; Face="Confident";
			Dialogue="Yeah, it done. Hope you like it."; 
			Reply="Great, now I can eat my beans in peace."};
		
	};
end

if RunService:IsServer() then
	-- MARK: Danny Handler
	Dialogues.Danny.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			dialog:SetInitiate("How's it going?", "Confident");
			
			if mission.ObjectivesCompleted["addWall1"]
			and mission.ObjectivesCompleted["addWall2"]
			and mission.ObjectivesCompleted["addWall3"]
			and mission.ObjectivesCompleted["addWall4"]
			and mission.ObjectivesCompleted["addWall5"] then
				dialog:AddChoice("spikingUp_complete", function(dialog)
					modMission:CompleteMission(player, missionId);
				end)
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("Hey, could you do me a favor?");
			
			dialog:AddChoice("spikingUp_start", function(dialog)
				dialog:AddChoice("spikingUp_sure", function(dialog)
					modMission:StartMission(player, missionId);
				end)
			end)
		
		elseif mission.Type == 3 then -- Complete
			
		end
	end
end


return Dialogues;