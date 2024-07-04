local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local SunkenShipCache = {
	Stage=0;
};


local mysteriousEngineerTag = '<b><font size="16" color="#ddcbb2">Mysterious Engineer</font></b>: ';

return function(player, dialog, data)
	if modBranchConfigs.IsWorld("SunkenShip") then 
		
		if modEvents:GetEvent(player, "mysteriousEngineerIntro") == nil then
			modEvents:NewEvent(player, {Id="mysteriousEngineerIntro"});
			
		else
			SunkenShipCache.Stage = 1;
			
			local npcModule = dialog:GetNpcModule();
			npcModule.Wield.Equip("walkietalkie");

			shared.Notify(game.Players:GetPlayers(), mysteriousEngineerTag.. "Hello hello! Okay, here we go again. Destroy those Nekron matter and go on down.. Good luck!", "Message");

		end
		
		if SunkenShipCache.Stage == 0 then
			dialog:SetInitiate("What the heck?? Who are you?!", "Question");

			dialog:AddChoice("sunkenShip_stumbled", function(dialog)
				dialog:AddChoice("sunkenShip_itleft", function(dialog)
					dialog:AddChoice("sunkenShip_getout", function(dialog)
						dialog:AddChoice("sunkenShip_death", function(dialog)
							dialog:AddChoice("sunkenShip_why", function(dialog)
								dialog:AddChoice("sunkenShip_whattodo", function(dialog)
									if SunkenShipCache.Stage == 0 then
										SunkenShipCache.Stage = 1;
										
										task.delay(3, function()
											local npcModule = dialog:GetNpcModule();
											npcModule.Wield.Equip("walkietalkie");

											shared.Notify(game.Players:GetPlayers(), mysteriousEngineerTag.. "Hello hello! Okay, walkie talkie works. Destroy those Nekron matter and go on down.. Good luck!", "Message");

										end)
									end
								end);
							end);
						end);
					end);
				end);
			end);
			
		elseif SunkenShipCache.Stage == 1 then
			dialog:SetInitiate("I'll keep in touch with this walkie talkie..", "Serious");

			local profile = shared.modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			local inventory = playerSave.Inventory;

			local function giveTubes(dialog)
				local itemId = "nekronparticulate";
				local total, itemList = inventory:ListQuantity(itemId, 4);

				if itemList then
					local giveItemId = "sunkenchest";

					local hasSpace = inventory:SpaceCheck{{ItemId=giveItemId}};
					if not hasSpace then
						shared.Notify(player, "Inventory is full!", "Negative");

					else
						if modEvents:GetEvent(player, "freeDivingSuit") == nil then
							giveItemId = "divingsuit";
							modEvents:NewEvent(player, {Id="freeDivingSuit"});
						end

						for a=1, #itemList do
							local itemLib = modItemsLibrary:Find(itemId);
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, ("4 $Item removed from your Inventory."):gsub("$Item", itemLib.Name), "Negative");
						end

						local rewardItemLib = modItemsLibrary:Find(giveItemId);
						inventory:Add(giveItemId, nil, function(queueEvent, storageItem)
							modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
						end);
						shared.Notify(player, "You recieved a ".. rewardItemLib.Name ..".", "Reward");
						
						modAudio.Play("StorageItemPickup", dialog.Prefab.PrimaryPart);
					end
						
					dialog:AddChoice("sunkenShip_give", function(dialog)
						local total, itemList = inventory:ListQuantity(itemId, 4);
						if itemList then
							local giveItemId = "sunkenchest";

							local hasSpace = inventory:SpaceCheck{{ItemId=giveItemId}};
							if not hasSpace then
								shared.Notify(player, "Inventory is full!", "Negative");

							else
								if modEvents:GetEvent(player, "freeDivingSuit") == nil then
									giveItemId = "divingsuit";
									modEvents:NewEvent(player, {Id="freeDivingSuit"});
								end

								for a=1, #itemList do
									local itemLib = modItemsLibrary:Find(itemId);
									inventory:Remove(itemList[a].ID, itemList[a].Quantity);
									shared.Notify(player, ("4 $Item removed from your Inventory."):gsub("$Item", itemLib.Name), "Negative");
								end

								local rewardItemLib = modItemsLibrary:Find(giveItemId);
								inventory:Add(giveItemId, nil, function(queueEvent, storageItem)
									modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
								end);
								shared.Notify(player, "You recieved a ".. rewardItemLib.Name ..".", "Reward");

								modAudio.Play("StorageItemPickup", dialog.Prefab.PrimaryPart);
							end
						end

						giveTubes(dialog);
					end);
				else
					dialog:AddChoice("sunkenShip_need");
				
				end
			end
			
			giveTubes(dialog);
		end
		
		
	else
		dialog:SetInitiate("Somehow, I'm in the outside world..", "Question");
		
	end
end
