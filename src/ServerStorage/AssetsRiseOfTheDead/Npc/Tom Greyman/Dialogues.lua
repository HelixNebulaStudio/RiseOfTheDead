local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {

};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		if math.random(1, 99) == 1 then
			dialog:InitDialog{
				Reply="... *creak*";
			}
		else
			dialog:InitDialog{
				Reply="...";
			}
		end
	end 
end

return Dialogues;