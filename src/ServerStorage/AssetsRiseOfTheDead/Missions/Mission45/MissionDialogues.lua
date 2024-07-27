local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Mike={};
};

local missionId = 45;
--==

-- MARK: Mike Dialogues
Dialogues.Mike.Dialogues = function()
	return {	
		{Tag="mlc_init"; Face="Serious";
			Dialogue="What's wrong? What did you left?"; 
			Reply="My lucky coin, I left it when I got out of prison."};

		{CheckMission=missionId; Tag="mlc_start"; Face="Smirk";
			Dialogue="I could help you look for it if you lead me there."; 
			Reply="Oh, that would be great. Whenever you are ready."};

		{Tag="mlc_found"; Face="Smirk";
			Dialogue="Is this the coin you were looking for?"; 
			Reply="YES! Oh, thanks so much."};
	};
end

if RunService:IsServer() then
	-- MARK: Mike Handler
	Dialogues.Mike.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		local profile = shared.modProfile:Get(player);
	
		if mission.Type == 2 then --Available
			dialog:SetInitiate("Ahh god.. Can't believe I left it.");
			dialog:AddChoice("mlc_init", function(dialog)
				dialog:AddChoice("mlc_start", function(dialog)
					modMission:StartMission(player, missionId);
				end)
			end);
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiate("Found it yet?", "Worried");
			
			if mission.ProgressionPoint == 4 or profile.Collectibles.mlc then
				dialog:AddChoice("mlc_found", function(dialog)
					modMission:CompleteMission(player, missionId);
				end)
			end
			
		end
	end
end


return Dialogues;