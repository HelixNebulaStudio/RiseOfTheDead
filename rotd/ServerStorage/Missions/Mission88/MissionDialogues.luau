local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Caitlin={};
};

local MISSION_ID = 88;
--==

-- MARK: Caitlin DialogueStrings
Dialogues.Caitlin.DialogueStrings = {
	["sot_init"]={
		Face="Worried";
		Reply="Stan saved my life, I was trapped and he heard me cried for help. I miss him so much..";
	};

	["sot_lore1a"] = {
		Face = "Smile";
		Say = "You have a sister?";
		Reply = "Yes, her name is Kimiko.";
	};
	["sot_lore1b"] = {
		Face = "Suspicious";
		Say = "How is Joseph suppose to help save your sister?";
		Reply = "Well, back then, my sisiter was sick and Joseph approached her and claimed that he was working on a \"miracle cure\" that could save her..";	
	};
	["sot_lore2b"] = {
		Face = "Smile";
		Say = "\"Miracle cure\"?";
		Reply = "That's what Kimiko told me, I'm not sure of the details..";	
	};
	["sot_lore1c"] = {
		Face = "Suspicious";
		Say = "Doesn't the Rats have a BioX scientist as well?";
		Reply = "Yes, but I don't think he works on the same project as Joseph..";
	};
	["sot_lore2c"] = {
		Face = "Bored";
		Say = "...";
		Reply = "I think Eugene is more in the genetic modification department.";
	};
};

if RunService:IsServer() then
	-- MARK: Caitlin Handler
	Dialogues.Caitlin.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available
			dialog:AddChoice("sot_lore1a");
			dialog:AddChoice({"sot_lore1b"; "sot_lore2b"});
			dialog:AddChoice({"sot_lore1c"; "sot_lore2c"});

		elseif mission.Type == 1 then -- Active
			-- local dialogPacket = {
			-- 	Face="Happy";
			-- 	Say="I've done killing the horde..";
			-- 	Reply="Wow, you better wash the blood off your clothes.";
			-- 	MissionId=0;
			-- };
			
			-- dialog:AddDialog(dialogPacket, function(dialog)
			-- 	modMission:CompleteMission(player, 0);
			-- end)
		end
	end
end


return Dialogues;