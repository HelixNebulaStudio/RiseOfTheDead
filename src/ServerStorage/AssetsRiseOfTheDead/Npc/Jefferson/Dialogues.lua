local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="*Ughhh*";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		local mission10 = modMission:GetMission(player, 10);
		if mission10 then return end;

		dialog:InitDialog{
			Reply="GET BACK! Stay away from me, I am infected.";
			Face="Frustrated";
		}
		dialog:AddChoice("infected_letmehelp", function(dialog)
			dialog:AddChoice("infected_insist", function(dialog)
				modMission:StartMission(player, 10);
			end)
		end)
		
	end 
end

return Dialogues;