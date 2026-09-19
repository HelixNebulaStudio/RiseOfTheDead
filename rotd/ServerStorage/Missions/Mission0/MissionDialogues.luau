local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Rachel={};
};

local MISSION_ID = 0;
--==

-- MARK: Rachel DialogueStrings
Dialogues.Rachel.DialogueStrings = {
	["template_init"]={
		Face="Worried";
		Reply="Yeah yeah yeah, yup yup yup..";
	};
};

if RunService:IsServer() then
	-- MARK: Rachel Handler
	Dialogues.Rachel.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

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