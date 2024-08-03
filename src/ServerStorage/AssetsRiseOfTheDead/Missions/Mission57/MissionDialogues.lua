local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	["Mr. Klaws"]={};
};

local missionId = 57;
--==

-- MARK: Mr. Klaws Dialogues
Dialogues["Mr. Klaws"].DialogueStrings = {
	["klawsWorkshop_init"]={
		CheckMission=missionId;
		Say="Sure, but where is your workshop?";
		Reply="Here's a map, good luck!";
	};
	["klawsWorkshop_done"]={
		Say="I found it, here you go..";
		Reply="Hah thanks! I am moving your name to the good list.";
	};
};

if RunService:IsServer() then
	-- MARK: Mr. Klaws Handler
	Dialogues["Mr. Klaws"].DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 3 then
				dialog:AddChoice("klawsWorkshop_done", function(dialog)
					modMission:CompleteMission(player, missionId);
				end)
			end
		
		elseif mission.Type == 2 then -- Available

			dialog:SetInitiate("Darn it, I just realized I left my journal in my workshop. Can you help me get it?", "Ugh");
			dialog:AddChoice("klawsWorkshop_init", function(dialog)
				
				local profile = shared.modProfile:Get(player);
				local activeInventory = profile.ActiveInventory;
				local hasSpace = activeInventory:SpaceCheck{
					{ItemId="klawsmap"; Data={Quantity=1}};
				};
				
				if hasSpace then
					activeInventory:Add("klawsmap");
					modMission:StartMission(player, missionId);
					shared.Notify(player, "You have received Mr. Klaw's Workshop Map!", "Positive");
					
				else
					shared.Notify(player, "Inventory is full!", "Negative");
				end
			end);
			
		end
	end
end


return Dialogues;