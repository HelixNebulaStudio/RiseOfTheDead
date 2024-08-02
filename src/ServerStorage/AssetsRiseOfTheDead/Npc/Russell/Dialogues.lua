local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Get out of my face! I'm trying to sleep.";
	};
	["init2"]={
		Reply="What do you want?!";
	};
	["init3"]={
		Reply="Stop messing about!";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local rngInitial = {
			"Get out of my face! I'm trying to sleep.";
			"What do you want?!";
			"Stop messing about!";
		}
		
		if math.random(1, 4) == 1 then
			dialog:SetInitiate(`Today is day {workspace:GetAttribute("DayOfYear") or 0} of the year..`, "Angry");
	
		else
			dialog:SetInitiate(rngInitial[math.random(1, #rngInitial)], "Angry");
		end
	end 
end

return Dialogues;