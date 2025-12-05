local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	["Mr. Klaws"]={};
};

local MISSION_ID = 46;
--==

-- MARK: Mr. Klaws Dialogues
Dialogues["Mr. Klaws"].DialogueStrings = {
	["warmup_init"]={
		Say="Sure, how do I do that?";
		Reply="You'll need coal. The zombies has been pretty naughty so they might drop some coal when you kill them.";
	};
	["warmup_start"]={
		CheckMission=MISSION_ID;
		Say="I'm on it.";
		Reply="Chip chop!";
	};
	["warmup_done"]={
		Say="I've started the fireplace.";
		Reply="Goodjob, it will keep these surivors warm and cozy.";
	};
};


if RunService:IsServer() then
	-- MARK: Mr. Klaws Handler
	Dialogues["Mr. Klaws"].DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 3 then
				dialog:AddChoice("warmup_done", function(dialog)
					local modUnlockPack = shared.require(game.ReplicatedStorage.Library.UsableItems.Generics.UnlockPack);
					modUnlockPack.UnlockPack(player, "SkinsPacks", "FestiveWrapping");

					modMission:CompleteMission(player, MISSION_ID);
				end)
			end
		
		elseif mission.Type == 2 then -- Available

			dialog:SetInitiate("Welp, looks like I'm stuck here for a while with the outside being so dum cold. I notice you guys do not have a fireplace before, so I created one, but I need your help igniting it.", "Surprise");
			dialog:AddChoice("warmup_init", function(dialog)
				dialog:AddChoice("warmup_start", function(dialog)
					modMission:StartMission(player, MISSION_ID);
				end);
			end);
			
		end
	end
end


return Dialogues;