local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Carlson={};
};

local missionId = 22;
--==

-- MARK: Carlson Dialogues
Dialogues.Carlson.DialogueStrings = {
	["thebackup_help"]={
		CheckMission=missionId;
		Say="Yup, what do you need help with?";
		Face="Serious"; 
		Reply="We are in deep trouble, we won't have enough food for the bandits the next time they attack.. I need you to help me get my hidden metal supplies to fortify this safehouse.";
	};
	["thebackup_thekey"]={
		Say="Absolutely, where is it?";
		Face="Confident"; 
		Reply="It's in the maintenance room, but I hid the room's key somewhere in the break room. Go find the key in order to unlock the maintenance room.";
	};
	
	["thebackup_gotit"]={
		Say="*Gives 1000 metal*";
		Face="Happy"; 
		Reply="Ah, there we go, it's all here.\n\nThanks a lot $PlayerName, we'll see how we can fortify the safehouse with it.";
	};
	["thebackup_wait"]={
		Say="Wait, I'm still getting it..";
		Face="Confident"; 
		Reply="Okay.";
	};
	["thebackup_stolen"]={
		Say="There wasn't any metal there.";
		Face="Frustrated"; 
		Reply="Noooo! The bandits must have some how gotten it too. This is bad, what are we going to do?!\n\nThanks again for trying to help, we'll have to figure out something else.";
	};

};

if RunService:IsServer() then
	-- MARK: Carlson Handler
	Dialogues.Carlson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:SetInitiate("The key's somewhere in the break room.");
				
			elseif mission.ProgressionPoint == 4 then
				dialog:SetInitiate("$PlayerName, did you get the 1000 metal?");
				
				local profile = shared.modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local total, itemList = inventory:ListQuantity("metal", 1000);
				if total >= 1000 then
					dialog:AddChoice("thebackup_gotit", function(dialog)
						if itemList then
							for a=1, #itemList do
								inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							end
							shared.Notify(player, "Removed 1000 Metal Scraps from your inventory.", "Negative");
							
							data:Set("thebackup_gaveMetal", true);
							modMission:CompleteMission(player, missionId);
						else
							shared.Notify(player, ("Unable to find items from inventory."), "Negative");
						end
					end);
				end
				dialog:AddChoice("thebackup_wait");
				dialog:AddChoice("thebackup_stolen", function(dialog)
					data:Set("thebackup_gaveMetal", false);
					modMission:CompleteMission(player, missionId);
				end);
				
			else
				dialog:SetInitiate("Gotta forify this place as soon as possible.");
			end
				
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("Hey, err.. $PlayerName was it?");
			dialog:AddChoice("thebackup_help", function(dialog)
				dialog:AddChoice("thebackup_thekey", function(dialog)
					modMission:StartMission(player, missionId);
				end)
			end)
			
		end
	end
end


return Dialogues;