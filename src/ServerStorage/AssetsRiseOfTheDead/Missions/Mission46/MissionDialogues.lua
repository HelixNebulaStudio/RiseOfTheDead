local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	["Mr. Klaws"]={};
};

local missionId = 46;
--==

-- MARK: Mr. Klaws Dialogues
Dialogues["Mr. Klaws"].Dialogues = function()
	return {
		{Tag="warmup_init";
			Dialogue="Sure, how do I do that?";
			Reply="You'll need coal. The zombies has been pretty naughty so they might drop some coal when you kill them."};
		{CheckMission=missionId; Tag="warmup_start";
			Dialogue="I'm on it.";
			Reply="Chip chop!"};
		{Tag="warmup_done";
			Dialogue="I've started the fireplace.";
			Reply="Goodjob, it will keep these surivors warm and cozy."};
	};
end

if RunService:IsServer() then
	-- MARK: Mr. Klaws Handler
	Dialogues["Mr. Klaws"].DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 3 then
				dialog:AddChoice("warmup_done", function(dialog)
					modMission:CompleteMission(player, missionId);
					local profile = shared.modProfile:Get(player);
					profile:Unlock("SkinsPacks", "FestiveWrapping", true);
				end)
			end
		
		elseif mission.Type == 2 then -- Available

			dialog:SetInitiate("Welp, looks like I'm stuck here for a while with the outside being so dum cold. I notice you guys do not have a fireplace before, so I created one, but I need your help igniting it.", "Surprise");
			dialog:AddChoice("warmup_init", function(dialog)
				dialog:AddChoice("warmup_start", function(dialog)
					modMission:StartMission(player, missionId);
				end);
			end);
			
		end
	end
end


return Dialogues;