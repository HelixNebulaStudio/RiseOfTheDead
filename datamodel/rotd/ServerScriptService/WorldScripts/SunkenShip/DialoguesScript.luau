local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {
	["Mysterious Engineer"] = {};
};
--==

-- MARK: Mysterious Engineer Dialogues
Dialogues["Mysterious Engineer"].DialogueStrings = {
	["init1"]={
		Reply="What the..";
	};

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
	-- MARK: Mysterious Engineer DialogueHandler
	Dialogues["Mysterious Engineer"].DialogueHandler = function(player, dialog, data)
		local modStorage = shared.modStorage;
		local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
		local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
		local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);
		local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
		local modRegionMission = shared.require(game.ServerScriptService.ServerLibrary.RegionMission);

		local gameController = shared.GameController;
		local regionMission = gameController and modRegionMission:GetById("CoopMission");

		local mysteriousEngineerNpcLib = modNpcProfileLibrary:Find("Mysterious Engineer");
		local mysteriousEngineerAvatar = mysteriousEngineerNpcLib.Avatar;

		if regionMission.CoopMission.CheckPoint == 4 then
			local introFlag = modEvents:GetEvent(player, "mysteriousEngineerIntro");
			Debugger:StudioLog(`mysteriousEngineerIntro`, introFlag)
			if introFlag == nil then
				modEvents:NewEvent(player, {Id="mysteriousEngineerIntro"});
				
			else
				local npcClass: NpcClass = dialog:GetNpcClass();
				local wieldComp: WieldComp = npcClass.WieldComp;
				wieldComp:Equip{
					ItemId = "walkietalkie";
				};

				regionMission:Progress(function(coopMission)
					if coopMission.CheckPoint == 4 then
						coopMission.CheckPoint = 5;
						coopMission.SaveData.Dialogues = {
							Dialogue1 = {
								AvatarId = mysteriousEngineerAvatar;
								Text = "Hello hello! Okay, here we go again. Destroy those Nekron matter and go on down.. Good luck!";
							};
						};
					end
				end)
			end

			dialog:SetInitiate("What the heck?? Who are you?!", "Question");

			dialog:AddChoice(
				{"sunkenShip_stumbled"; "sunkenShip_itleft"; "sunkenShip_getout"; 
				"sunkenShip_death"; "sunkenShip_why"; "sunkenShip_whattodo"}, 
				function(dialog)
					regionMission:Progress(function(coopMission)
						if coopMission.CheckPoint == 4 then
							coopMission.CheckPoint = 5;
							coopMission.SaveData.Dialogues = {
								Dialogue1 = {
									AvatarId = mysteriousEngineerAvatar;
									Text = "Hello hello! Okay, walkie talkie works. Destroy those Nekron matter and go on down.. Good luck!";
								};
							};
						end
					end)
					
					task.delay(3, function()
						local npcClass: NpcClass = dialog:GetNpcClass();
						local wieldComp: WieldComp = npcClass.WieldComp;
						wieldComp:Equip{
							ItemId = "walkietalkie";
						};
					end)
				end
			);
			
		elseif regionMission.CoopMission.CheckPoint >= 5 then
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
						
						modAudio.Play("StorageItemPickup", dialog.Character.PrimaryPart);
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

								modAudio.Play("StorageItemPickup", dialog.Character.PrimaryPart);
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
	end
end


return Dialogues;