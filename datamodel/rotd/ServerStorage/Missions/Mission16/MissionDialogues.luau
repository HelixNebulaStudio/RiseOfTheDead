local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Jesse={};
};

local MISSION_ID = 16;
--==

-- MARK: Jesse Dialogues
Dialogues.Jesse.DialogueStrings = {
	["aGoodDeal_start"]={
		CheckMission=MISSION_ID;
		Say="Sure, I can help."; 
		Face="Skeptical"; Reply="Alright, find me 2 Igniters but don't take too long. I got customers waiting..";
	};
	
	["aGoodDeal_notYet"]={
		Say="Still working on it.";
		Face="Question"; 
		Reply="Alright, but don't take too long. I got customers waiting..";
	};
	["aGoodDeal_done"]={
		Say="Here you go."; 
		Face="Smirk"; 
		Reply="Alright, great, come back tomorrow. I might have some interesting items to offer for more of your work.";
	};

	["aGoodDeal_questions"]={
		Say="Hey, this is the first time you are outside the shop!"; 
		Reply="Yes, I wanted to take a breath of the fresh air..";
		ReturnToInit=true;
	};
	["aGoodDeal_org"]={
		Say="Who do you work for?"; 
		Reply="R.A.T., now stop asking..";
		ReturnToInit=true;
	};
	["aGoodDeal_why"]={
		Say="Why are you working in this apocalypse?"; 
		Reply="I work for them and they protect me alright? I'm not going to answer anymore questions.";
		ReturnToInit=true;
	};
};

if RunService:IsServer() then
	-- MARK: Jesse Handler
	Dialogues.Jesse.DialogueHandler = function(player, dialog, data, mission)
		local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			dialog:SetInitiate("Have you found the 2 igniters yet?");
			if mission.ObjectivesCompleted["IgniterSearch"] == true then
				dialog:AddChoice("aGoodDeal_done", function(dialog)
					local profile = shared.modProfile:Get(player);
					local playerSave = profile:GetActiveSave();
					local inventory = playerSave.Inventory;
					
					local total, itemList = inventory:ListQuantity("igniter", 2);
					if itemList then
						for a=1, #itemList do
							local itemLib = modItemsLibrary:Find("igniter");
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, ("$Amount$Item removed from your Inventory."):gsub("$Item", itemLib.Name):gsub("$Amount", itemList[a].Quantity > 1 and itemList[a].Quantity.." " or ""), "Negative");
						
						end
						modMission:CompleteMission(player, MISSION_ID);
						delay(20, function()
							if modMission:GetMission(player, 17) == nil then
								modMission:AddMission(player, 17);
							end
						end)
					else
						shared.Notify(player, ("Unable to find items from inventory."), "Negative");
					end
				end)
			else
				dialog:AddChoice("aGoodDeal_notYet");
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("Hey, wanna make some quick dough?");
			dialog:AddChoice("aGoodDeal_questions");
			dialog:AddChoice("aGoodDeal_org");
			dialog:AddChoice("aGoodDeal_why");
			dialog:AddChoice("aGoodDeal_start", function(dialog)
				modMission:StartMission(player, MISSION_ID);
			end)
			
		end
	end
end


return Dialogues;