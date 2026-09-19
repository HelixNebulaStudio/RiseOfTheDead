local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Yo, need any help?";
	};
	["init2"]={
		Reply="Whachu doing?";
	};
	["init3"]={
		Reply="We really need to take back what's ours!";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["general_fast"]={
		Face="Joyful";
		Say="You run really fast.";
		Reply="Thanks, survival of the fittest right!";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		
		local mission62 = modMission:GetMission(player, 62);
		if mission62 and mission62.Type == 1 then return end;
		
		local mission30 = modMission:GetMission(player, 30);
		if mission30 and mission30.ProgressionPoint > 1 then
			dialog:AddChoice("general_fast");
		end
	end 
end

return Dialogues;