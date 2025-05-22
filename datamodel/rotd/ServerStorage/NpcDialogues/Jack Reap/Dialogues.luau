local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="I have never felt so alive...";
	};
	["init2"]={
		Reply="Ah, music to my ears..";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		if modMission:GetMission(player, 31) == nil then
			dialog:AddChoice("egghunt_init", function(dialog)
				dialog:AddChoice("egghunt_find", function(dialog)
					modMission:StartMission(player, 31);
				end)
			end)
		end
	end 
end

return Dialogues;