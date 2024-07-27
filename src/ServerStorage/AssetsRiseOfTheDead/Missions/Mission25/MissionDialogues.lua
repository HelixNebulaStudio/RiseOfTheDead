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
Dialogues["Mr. Klaws"].Dialogues = function()
	return {
		{Tag="xmasramp_yes"; Dialogue="Umm, yes.";
			Face="Confident"; Reply="Well, I need you to kill some zombies which are wearing santa hats."};
		{CheckMission=missionId;Tag="xmasramp_start"; Dialogue="Oh, that sounds easy. I'll do it.";
			Face="Joyful"; Reply="Good luck out there!"};
		{Tag="xmasramp_done"; Dialogue="It's done.";
			Face="Surprise"; Reply="Wow, you got it done."};
		{Tag="xmasramp_almost"; Dialogue="Yeah, am I on the nice list now?";
			Face="Smirk"; Reply="Oh ho ho, I won't reveal that."};
	};
end

if RunService:IsServer() then
	-- MARK: Mr. Klaws Handler
	Dialogues["Mr. Klaws"].DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 2 then
				dialog:AddChoice("xmasramp_done", function(dialog)
					dialog:AddChoice("xmasramp_almost", function(dialog)
						modMission:CompleteMission(player, missionId);
						local profile = shared.modProfile:Get(player);
						profile:Unlock("SkinsPacks", "Xmas", true);
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