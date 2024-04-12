local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Rachel={};
};

local missionId = 0;
--==

-- !outline: Rachel Dialogues
Dialogues.Rachel.Dialogues = function()
	return {
	};
end

if RunService:IsServer() then
	-- !outline: Rachel Handler
	Dialogues.Rachel.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active

		end
	end
end


return Dialogues;