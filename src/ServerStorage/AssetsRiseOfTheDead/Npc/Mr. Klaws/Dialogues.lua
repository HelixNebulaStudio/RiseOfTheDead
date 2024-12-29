local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Ho ho HO!!!";
	};
	["init2"]={
		Reply="Merry Christmas fellow person..";
	};
	["init3"]={
		Reply="Eyy, it's a holiday.";
	};
	["init4"]={
		Reply="Feeling the Christmas spirit?";
	};
	["init5"]={
		Reply="Got any coal? I'll trade ya for it.";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["general_spirit"]={
		Say="Merry Christmas!";
		Reply="Merry Christmas to you too!";
	};
	
	["general_trade"]={
		Say="Do you want some coal?";
		Reply="Yes! Give it to me, and I will give you something in return.";
	};

	["xmas2019"]={
		Say="I got 300 coal.";
		Reply="Ho ho, that's great, here I'll trade you a present for the 300 coal.";
	};
	["xmas2020"]={
		Say="I got 200 coal.";
		Reply="Ho ho, that's great, here I'll trade you a present for the 200 coal.";
	};
	["xmas2021"]={
		Say="I got 100 coal.";
		Reply="Ho ho, that's great, here I'll trade you a present for the 100 coal.";
	};
	
	["general_giftSanta"]={
		Say="*Gift Mr. Klaws a Present*";
		Reply="Why thank you! I see you are in the Christmas Spirit, but that's a present from me to you.\n\n*Gift present back to you*";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
		local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
		local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
		local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
		local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
		local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);
		local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
	
		local profile = modProfile:Get(player);
		local playerSave = profile:GetActiveSave();
		local inventory = playerSave.Inventory;
		local playerLevel = playerSave and playerSave:GetStat("Level") or 1;
		

		--MARK: Yearly Present claim;
		local yearVal = os.date("*t")["year"];
		local yearlyPresentItemLib = modItemsLibrary:Find(`xmaspresent{yearVal}`);
		if yearlyPresentItemLib then
			local flagId = `xmaspresent{yearVal}Claim`
			local yearlyPresentId = yearlyPresentItemLib.Id;

			local yearlyPresentFlag = profile.Flags:Get(flagId);
			if yearlyPresentFlag == nil then
				local hasSpace = inventory:SpaceCheck{
					{ItemId=yearlyPresentId; Data={Quantity=1}};
				};
				
				local dialogPacket = {
					Face="Happy";
					Say="Claim your end of ".. yearVal .." present";
				}
				
				local lvlRequirement = math.round(modGlobalVars.MaxLevels/2);
				if playerLevel < lvlRequirement then
					dialogPacket.Reply="You need mastery level "..lvlRequirement.." to claim this.";
					
				elseif hasSpace == false then
					dialogPacket.Reply="Your inventory is a bit full.. Ho ho ho!";
					
				else
					dialogPacket.Reply="Here you go!";
					profile.Flags:Add({Id=flagId});
		
					inventory:Add(yearlyPresentId, nil, function(queueEvent, storageItem)
						modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
					end);
					shared.Notify(player, "You recieved a ".. yearlyPresentItemLib.Name ..".", "Reward");
					
				end
				dialog:AddDialog(dialogPacket);
				
				if playerLevel > lvlRequirement then
					dialog:SetInitiate("Merry Christmas! Time to claim your end of ".. yearVal .." present!");
					return;
				end
			end
		end
		

		--== ActiveSkin
		local presentsRequired = 2;
		local total, itemList = inventory:ListQuantity("xmaspresent2022", presentsRequired);
		local aaMissions = modMission:GetNpcMissions(player, script.Name);
		
		Debugger:Log("total", total, "activeMissions", aaMissions)
		if total >= presentsRequired and #aaMissions <= 0 then
			dialog:SetInitiate("Hey, I'm running low on presents, if you can give me <b>".. presentsRequired .." Christmas Presents 2022</b>, I will trade it for a special tool pattern.");
			
			local dialogPacket = {
				Face="Happy";
				Say="I have ".. presentsRequired .." Christmas Presents 2022 for you.";
			}
			
			local equippedToolID = profile.EquippedTools.ID;
			local storageItem = inventory:Find(equippedToolID);
	
			local itemDisplayLib = storageItem and modWorkbenchLibrary.ItemAppearance[storageItem.ItemId];
			
			if itemDisplayLib then
				local modSkinPerm = require(game.ReplicatedStorage.BaseLibrary.UsableItems.Generics.SkinPerm);
				local winterFestSkinId = "105";
	
				if not modSkinPerm:HasSkinPermanent(storageItem, winterFestSkinId) then
					dialogPacket.Reply="Hope you like it, I've given it a pattern. Oh, and you need to remove any textures before it's visible.";
					dialog:AddDialog(dialogPacket, function(dialog)
						modSkinPerm:AddSkinPermanent(storageItem, winterFestSkinId);
	
						for a=1, #profile.EquippedTools.WeaponModels do
							if profile.EquippedTools.WeaponModels[a]:IsA("Model") then
								local modColorsLibrary = require(game.ReplicatedStorage.Library.ColorsLibrary);
								modColorsLibrary.ApplyAppearance(profile.EquippedTools.WeaponModels[a], storageItem.Values);
							end
						end
						
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, presentsRequired.." Christmas Presents 2022 removed from your Inventory.", "Negative");
							
						end
					end);
					
				else
					dialogPacket.Reply="The tool you equipped already has the skin permanent.";
					dialog:AddDialog(dialogPacket);
					
				end
				
			elseif storageItem then
				dialogPacket.Reply="The tool you equipped cannot be customized.";
				dialog:AddDialog(dialogPacket);
				
			else
				dialogPacket.Reply="Equip a tool that you want me to customize first.";
				dialog:AddDialog(dialogPacket);
				
			end
			
		end
		
		--== XmasSpirit;
		
		local event = modEvents:GetEvent(player, "xmasSpirit");
		local timer = event and event.Time;
	
		if timer == nil or modSyncTime.GetTime() >= timer then
			dialog:AddChoice("general_spirit", function(dialog)
				modEvents:NewEvent(player, {Id="xmasSpirit"; Time=modSyncTime.GetTime()+1200;});
	
				modStatusEffects.FrostivusSpirit(player, 300);
			end);
		end
		
		--== Gift Exchange
		
		local function gift(coalAmount, rewardId)
			local total, itemList = inventory:ListQuantity("coal", coalAmount);
			if total >= coalAmount then
				local hasSpace = inventory:SpaceCheck{
					{ItemId=rewardId; Data={Quantity=1}};
				};
				
				if hasSpace then
					for a=1, #itemList do
						inventory:Remove(itemList[a].ID, itemList[a].Quantity);
					end
	
					local itemInfo = modItemsLibrary:Find(rewardId);
					
					inventory:Add(rewardId, nil, function(queueEvent, storageItem)
						modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
					end);
					shared.Notify(player, "You recieved a ".. itemInfo.Name ..".", "Reward");
					shared.Notify(player, "Removed ".. coalAmount .." Coal from your inventory.", "Negative");
				else
					shared.Notify(player, ("Inventory Full!"), "Negative");
				end
			else
				shared.Notify(player, ("Not enough coal."), "Negative");
			end
		end
		
		dialog:AddChoice("general_trade", function(dialog)
			local total = inventory:CountItemId("coal");
			
			dialog:AddChoice("xmas2019", function(dialog)
				gift(300, "xmaspresent")
			end)
			
			dialog:AddChoice("xmas2020", function(dialog)
				gift(200, "xmaspresent2020")
			end)
			
			dialog:AddChoice("xmas2021", function(dialog)
				gift(100, "xmaspresent2021")
			end)
		end)
		
		--dialog:AddChoice("general_giftSanta");

	end 
end

return Dialogues;