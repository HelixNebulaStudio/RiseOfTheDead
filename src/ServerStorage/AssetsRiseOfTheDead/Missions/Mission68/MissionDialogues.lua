local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Rachel={};
};

local missionId = 0;
--==

-- MARK: Rachel Dialogues
Dialogues.Rachel.DialogueStrings = {
	["medbre_init"]={
		Face="Worried";
		Reply="Stan saved my life, I was trapped and he heard me cried for help. I miss him so much..";
	};

	["medbre_start"]={
		CheckMission=missionId;
		Say="Hey, it's okay. I have some news about Stan.";
		Face="Worried"; 
		Reply="News.. about Stan?";
		FailResponses = {
			{Reply="You're too new here, come back once you're more familiar with the place."};
		};
	};
	["medbre_start2"]={
		Say="Yes, so apparently Stan is still alive.";
		Face="Disbelief"; 
		Reply="...";
	};

};


if RunService:IsServer() then
	-- MARK: Rachel Handler
	Dialogues.Rachel.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active

			-- local dialogPacket = {
			-- 	Face="Happy";
			-- 	Say="I've done killing the horde..";
			-- 	Reply="Wow, you better wash the blood off your clothes.";
			-- 	MissionId=0;
			-- };
			
			-- dialog:AddDialog(dialogPacket, function(dialog)
			-- 	modMission:CompleteMission(player, 0);
			-- end)
		end
	end
end


return Dialogues;