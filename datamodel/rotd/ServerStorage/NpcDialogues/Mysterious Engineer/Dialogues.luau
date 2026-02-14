local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="What the..";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["sunkenShip_stumbled"]={
		Face="Question";
		Say="Oh I'm sorry.. I was told to search for something in the seabed but I stumbled on to this place..";
		Reply="Wait wait wait, how did you get pass that gigantic worm outside?";
	};
	["sunkenShip_itleft"]={
		Face="Surprise";
		Say="I shot at it a couple of times and it left..";
		Reply="Oh no... It will be back after a while, and it might destroy everything.."};
	["sunkenShip_getout"]={
		Face="Skeptical";
		Say="We should get out of here then..";
		Reply="This is my home, I'm not leaving this place for the surface above that is overruned by zombies and bandits.";
	};
	["sunkenShip_death"]={
		Face="Skeptical";
		Say="But what about the Elder Vexeron?";
		Reply="Hmmm, I think I can put the worm back to sleep. It wasn't suppose to wake up that easily, I don't think shooting it a couple times was the real reason it woke up.";
	};
	["sunkenShip_why"]={
		Face="Welp";
		Say="How are you going to put it back to sleep?";
		Reply="I need your help. A few months ago, an explosion from the North shook the ship and parts of it collapsed and flooded some sections.";
	};
	["sunkenShip_whattodo"]={
		Face="Welp";
		Say="So what do you need me to do?";
		Reply="I need you to salvage as many tubes of Nekron Particulates as you can. I'll reward you handsomely for them.";
	};
	
	
	["sunkenShip_give"]={
		Face="Bored";
		Say="I managed to salvage some tubes.. *give 4 tubes*";
		Reply="Alright, thanks. Here's something for the trouble.";
	};
	["sunkenShip_need"]={
		Face="Bored";
		Say="What am I looking for?";
		Reply="Look for tubes of nekron particulates, I'll give you something for every 4 tubes you find.";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
		local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
		local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
		local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
		local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

		local SunkenShipCache = {
			Stage=0;
		};

		local mysteriousEngineerTag = '<b><font size="16" color="#ddcbb2">Mysterious Engineer</font></b>: ';

		if modBranchConfigurations.IsWorld("SunkenShip") then 
			if modEvents:GetEvent(player, "mysteriousEngineerIntro") == nil then
				modEvents:NewEvent(player, {Id="mysteriousEngineerIntro"});
				
			else
				SunkenShipCache.Stage = 1;
				
				local npcModule = dialog:GetNpcClass();
				npcModule.Wield.Equip("walkietalkie");
	
				shared.Notify(game.Players:GetPlayers(), mysteriousEngineerTag.. "Hello hello! Okay, here we go again. Destroy those Nekron matter and go on down.. Good luck!", "Message");
	
			end
			
			if SunkenShipCache.Stage == 0 then
				dialog:SetInitiate("What the heck?? Who are you?!", "Question");
	
				dialog:AddChoice(
					{"sunkenShip_stumbled"; "sunkenShip_itleft"; "sunkenShip_getout"; 
					"sunkenShip_death"; "sunkenShip_why"; "sunkenShip_whattodo"}, 
					function(dialog)
						if SunkenShipCache.Stage == 0 then
							SunkenShipCache.Stage = 1;
							
							task.delay(3, function()
								local npcModule = dialog:GetNpcClass();
								npcModule.Wield.Equip("walkietalkie");

								shared.Notify(game.Players:GetPlayers(), mysteriousEngineerTag.. "Hello hello! Okay, walkie talkie works. Destroy those Nekron matter and go on down.. Good luck!", "Message");

							end)
						end
					end
				);
				
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
end

return Dialogues;