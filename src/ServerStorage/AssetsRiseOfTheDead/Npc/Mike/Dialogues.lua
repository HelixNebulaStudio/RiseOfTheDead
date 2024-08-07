local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="I wanted freedom, but this isn't what I was expecting..";
	};
	["init2"]={
		Reply="I'm prison mike!";
	};
	["init3"]={
		Reply="Freeedom!";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["travel_prison"]={
		Say="Could you take me to the Wrighton Dale Prison?";
		Reply="I guess..";
	};

	["general_inprison"]={
		Say="Why were you in prison?"; 
		Reply="I was on a job.. A heist all planned out, a three man job.. But I was backstabbed.. They threw me under the bus and they escaped. This was years ago.";
	};
	["general_how"]={
		Say="How did you escape?"; 
		Reply="A cellmate of mine heard that one of the prisoner volunteered into a special program.. He was transported to some lab one day, and been gone the whole day. Few days after that, he's been acting strange.\n\nThat night, we all heard a huge roar, the guards unlocked his cell to try to get him out back to the lab.";
	};
	["general_how2"]={
		Say="And then what happened?"; 
		Reply="THAT PRISONER SENT THE GUARD FLYING!! He then forced some of the prison gates open and the control room caught on fire. Next thing I know, all the cells are unlocked and I got out of there as fast as I could.";
	};

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		
		local mission45 = modMission:GetMission(player, 45);
		if mission45 and mission45.ProgressionPoint >= 1 then
			dialog:AddChoice("travel_prison", function()
				local npcModel = dialog.Prefab;
				if npcModel:FindFirstChild("prisonInteractable") then
					dialog:InteractRequest(npcModel.prisonInteractable, npcModel.PrimaryPart);
				end
			end);
		end
		
		dialog:AddChoice("general_inprison");
		dialog:AddChoice("general_how", function(dialog)
			dialog:AddChoice("general_how2");
		end);
	end 
end

return Dialogues;