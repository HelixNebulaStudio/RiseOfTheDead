local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Hello, how may I help you?";
	};
	["init2"]={
		Reply="Hey, how are you?";
	};
	["init3"]={
		Reply="Yes? Do you need some help?";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["general_takenOver"]={
		Say="I still can't believe what happened to the world."; 
		Reply="Me neither, the world is taken over by the zombies.";
	};
	["general_russellSaved"]={
		Say="How did you end up here?"; 
		Reply="I was trapped in my clothing store for 8 hours when everything happened, then Russell showed up. Killing a bunch of the dead to get me out of the store and brought me here.";
	};
	["general_howsNick"]={
		Say="How are you?"; 
		Reply="Pretty well, I was terrified when I was trapped outside, now I feel much safer now.";
	};

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		dialog:AddChoice("general_takenOver");
		dialog:AddChoice("general_russellSaved");
		dialog:AddChoice("general_howsNick");
	end 
end

return Dialogues;