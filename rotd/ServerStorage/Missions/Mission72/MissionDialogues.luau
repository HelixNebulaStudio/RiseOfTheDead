local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Mason = {};
};

local MISSION_ID = 72;
--==

-- !outline: Mason Dialogues
Dialogues.Mason.DialogueStrings = {
	["newweapon_init"]={
		Say = "Good, but I think I need a secondary weapon in case I run out of bullets..";
		Face = "Smirk"; 
		Reply = "Why of course, the more weapons the better right?";
	};
	["newweapon_init2"]={
		Say = "Yeah, so where can I get more weapons?"; 
		Face = "Confident"; 
		Reply = "Talk to the shop keeper, he sells weapon blueprints which you can buy to build.\n\nYou can also find blueprints when you kill the big bads around the world.";
	};

	["newweapon_help1"]={
		Say = `Wait, who are these "Big Bads" you're talking about?`;
		Face = "Grumpy"; 
		Reply = "Some of these zombies are unlike the others, they have special abilties and are very dangerous, however they guard special loot.\n\nThere are also some rogue humans driven insane from the apocalpyse.. Or maybe they are also infected but in a different way.. Who knows. Anyways, stay clear from them.";
	};
	["newweapon_help2"]={
		Say = `I got the blueprint, what do I do?`;
		Face = "Happy";
		Reply = "Use it on the workbench, it will show you what you need to collect to build the item.";
	};
};


if RunService:IsServer() then

	Dialogues.Mason.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("How are the upgrades feeling?", "Happy");
			dialog:AddChoice({"newweapon_init"; "newweapon_init2"}, function(dialog)
				modMission:StartMission(player, MISSION_ID);
			end);
			
		elseif mission.Type == 1 then -- Active

			dialog:AddChoice("newweapon_help1");
			dialog:AddChoice("newweapon_help2");
			
		end
	end

end


return Dialogues;