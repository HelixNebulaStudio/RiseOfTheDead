local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Ugggh..";
	};
	["init2"]={
		Reply="Neeed moore eeeggs..";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["reborn_lore1="]={
		Say="What's with all the Bunny Masks?"; 
		Reply="I was lost, lost in the woods. A bunny accompanied me in my solitude. A loud explosion guided me back to civilization. In the end bunny gave it's life for me to survive.";
	};
	["reborn_lore2"]={
		Say="What is this place?"; 
		Reply="This is my home now, with a bunch of zombies accompanying me, I feel.. safe.";
	};
	["reborn_lore3"]={
		Say="Why are you searching for those eggs?"; 
		Reply="It guides me, something inside.. which I need.";
	};
	["reborn_lore4"]={
		Say="Why do the zombies ignore me when I wear this bunny mask?"; 
		Reply="They are confused, lack of other senses.. Their controller could be weakened during the time..";
	};

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
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