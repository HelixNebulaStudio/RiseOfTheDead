local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	["Mr. Klaws"]={};
};

local missionId = 25;
--==

-- MARK: Mr. Klaws Dialogues
Dialogues["Mr. Klaws"].DialogueStrings = {
	["xmasramp_yes"]={
		Say="Umm, yes.";
		Face="Confident"; 
		Reply="Well, I need you to kill some zombies which are wearing santa hats.";
	};
	["xmasramp_start"]={
		CheckMission=missionId;
		Say="Oh, that sounds easy. I'll do it.";
		Face="Joyful"; 
		Reply="Good luck out there!";
	};
	["xmasramp_done"]={
		Say="It's done.";
		Face="Surprise"; 
		Reply="Wow, you got it done.";
	};
	["xmasramp_almost"]={
		Say="Yeah, am I on the nice list now?";
		Face="Smirk"; 
		Reply="Oh ho ho, I won't reveal that.";
	};
};

if RunService:IsServer() then
	-- MARK: Mr. Klaws Handler
	Dialogues["Mr. Klaws"].DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 2 then
				dialog:AddChoice("xmasramp_done", function(dialog)
					dialog:AddChoice("xmasramp_almost", function(dialog)
						local modUnlockPack = shared.require(game.ReplicatedStorage.Library.UsableItems.Generics.UnlockPack);
						modUnlockPack.UnlockPack(player, "SkinsPacks", "Xmas");

						modMission:CompleteMission(player, missionId);
					end);
				end)
			end
		
		elseif mission.Type == 2 then -- Available

			dialog:SetInitiate("Heyhey, $PlayerName. You are a few point short from being on the nice list. Do you want to be on the nice list?", "Happy");
			dialog:AddChoice("xmasramp_yes", function(dialog)
				dialog:AddChoice("xmasramp_start", function(dialog)
					modMission:StartMission(player, missionId);
				end);
			end);
			
		end
	end
end


return Dialogues;