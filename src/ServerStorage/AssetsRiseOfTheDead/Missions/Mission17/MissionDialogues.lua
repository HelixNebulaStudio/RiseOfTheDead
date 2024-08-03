local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Jesse={};
};

local missionId = 17;
--==

-- !outline: Jesse Dialogues
Dialogues.Jesse.DialogueStrings = {		
	["partTime_start"]={
		CheckMission=missionId;
		Say="What do you need this time?";
		Face="Skeptical"; 
		Reply="Get me this list of items, and make it snappy.";
		FailResponses = {
			{Reply="What?"};
		};	
	};
	["restock_done"]={
		Say="Here you go.";
		Face="Smirk"; 
		Reply="Nicely done, same thing tomorrow.";
	};
	["restock_donefull"]={
		Say="Here you go.";
		Face="Smirk"; 
		Reply="First, make some space in your inventory..";
	};
};

if RunService:IsServer() then
	local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
	
	-- !outline: Jesse Handler
	Dialogues.Jesse.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("Hey, ready for another job?");
			dialog:AddChoice("aGoodDeal_org");
			dialog:AddChoice("aGoodDeal_why");
			dialog:AddChoice("partTime_start", function(dialog)
				modMission:StartMission(player, missionId);
			end)
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiate("Have you found the items yet?");
			if mission.ObjectivesCompleted["Search"] == true then

				if modMission:CanCompleteMission(player, missionId, true) then
					dialog:AddChoice("restock_done", function(dialog)
						local profile = shared.modProfile:Get(player);
						local playerSave = profile:GetActiveSave();
						local inventory = playerSave.Inventory;

						local total, itemList = inventory:ListQuantity(mission.SaveData.ItemId, mission.SaveData.Amount);
						if itemList then
							for a=1, #itemList do
								local itemLib = modItemsLibrary:Find(mission.SaveData.ItemId);
								inventory:Remove(itemList[a].ID, itemList[a].Quantity);
								shared.Notify(player, ("$Amount$Item removed from your Inventory."):gsub("$Item", itemLib.Name):gsub("$Amount", itemList[a].Quantity > 1 and itemList[a].Quantity.." " or ""), "Negative");

							end
							modMission:CompleteMission(player, missionId);
						else
							shared.Notify(player, ("Unable to find items from inventory."), "Negative");
						end
					end)
					
				else
					dialog:AddChoice("restock_donefull");
					
				end
			else
				dialog:AddChoice("aGoodDeal_notYet");
			end
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;