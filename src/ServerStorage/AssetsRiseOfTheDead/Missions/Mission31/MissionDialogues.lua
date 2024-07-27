local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	["Bunny Man"]={};
};

local missionId = 31;
--==

-- MARK: Bunny Man Dialogues
Dialogues["Bunny Man"].Dialogues = function()
	return {
		{CheckMission=missionId; Tag="egghunt_init";
			Dialogue="Who are you?!";
			Reply="I'm the Bunny Man, what do you want..?"};
		{Tag="egghunt_find";
			Dialogue="What are you doing here?"; 
			Reply="I'm searching for eggs. You know what. Help me find the Easter Eggs.."};
		{Tag="egghunt_end";
			Dialogue="Here I found some.."; 
			Reply="Good.. good..."};
		{Tag="egghunt_where";
			Dialogue="Where do I find the Easter Eggs?"; 
			Reply="Hmmm, never thought about that.. Just look around.."};
		{Tag="egghunt_invfull";
			Dialogue="Here I found some.."; 
			Reply="Your inventory is full."};
	};
end

if RunService:IsServer() then
	-- MARK: Bunny Man Handler
	Dialogues["Bunny Man"].DialogueHandler = function(player, dialog, data, mission)
		local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ObjectivesCompleted["EggHunt"] == true then
				if modMission:CanCompleteMission(player, missionId) then
					dialog:AddChoice("egghunt_end", function(dialog)
						local profile = shared.modProfile:Get(player);
						local playerSave = profile:GetActiveSave();
						local inventory = playerSave.Inventory;
						
						local _, itemList = inventory:ListQuantity("easteregg2023", 3);
						if itemList then
							local itemLib = modItemsLibrary:Find("easteregg2023");
							for a=1, #itemList do
								inventory:Remove(itemList[a].ID, itemList[a].Quantity);
								shared.Notify(player, ("$Amount$Item removed from your Inventory."):gsub("$Item", itemLib.Name):gsub("$Amount", itemList[a].Quantity > 1 and itemList[a].Quantity.." " or ""), "Negative");
							end
							modMission:CompleteMission(player, missionId);
						else
							shared.Notify(player, ("Unable to find items from inventory."), "Negative");
						end
					end)
				else
					dialog:AddChoice("egghunt_invfull");
				end
			else
				dialog:AddChoice("egghunt_where");
			end
		end
	end
end


return Dialogues;