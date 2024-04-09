local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modTradingService = require(game.ServerScriptService.ServerLibrary.TradingService);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

return function(player, dialog, data)
	local npcName = dialog.Name;
	
	local profile = modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local inventory = playerSave.Inventory;
	local playerLevel = playerSave and playerSave:GetStat("Level") or 1;
	
	--== 2023 claim;
	local present23Flag = profile.Flags:Get("xmaspresent2023Claim");
	if present23Flag == nil then
		local present23ItemId = "xmaspresent2023";
		
		local hasSpace = inventory:SpaceCheck{
			{ItemId=present23ItemId; Data={Quantity=1}};
		};
		
		local yearVal = os.date("*t")["year"];
		local dialogPacket = {
			Face="Happy";
			Dialogue="Claim your end of ".. yearVal .." present";
		}
		
		local lvlRequirement = math.round(modGlobalVars.MaxLevels/2);
		if playerLevel < lvlRequirement then
			dialogPacket.Reply="You need mastery level "..lvlRequirement.." to claim this.";
			
		elseif hasSpace == false then
			dialogPacket.Reply="Your inventory is a bit full.. Ho ho ho!";
			
		else
			dialogPacket.Reply="Here you go!";
			profile.Flags:Add({Id="xmaspresent2023Claim"});

			local itemInfo = modItemsLibrary:Find(present23ItemId);

			inventory:Add(present23ItemId, nil, function(queueEvent, storageItem)
				modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
			end);
			shared.Notify(player, "You recieved a ".. itemInfo.Name ..".", "Reward");
			
		end
		dialog:AddDialog(dialogPacket);
		
		if playerLevel > lvlRequirement then
			dialog:SetInitiate("Merry Christmas! Time to claim your end of ".. yearVal .." present!");
			return;
		end
	end
	
	--== LockedPattern
	local presentsRequired = 2;
	local total, itemList = inventory:ListQuantity("xmaspresent2022", presentsRequired);
	local aaMissions = modMission:GetNpcMissions(player, script.Name);
	
	Debugger:Log("total", total, "activeMissions", aaMissions)
	if total >= presentsRequired and #aaMissions <= 0 then
		dialog:SetInitiate("Hey, I'm running low on presents, if you can give me <b>".. presentsRequired .." Christmas Presents 2022</b>, I will trade it for a special tool pattern.");
		
		local dialogPacket = {
			Face="Happy";
			Dialogue="I have ".. presentsRequired .." Christmas Presents 2022 for you.";
		}
		
		local equippedToolID = profile.EquippedTools.ID;
		local storageItem = inventory:Find(equippedToolID);

		local itemDisplayLib = storageItem and modWorkbenchLibrary.ItemAppearance[storageItem.ItemId];
		
		if itemDisplayLib then
			
			if storageItem.Values.LockedPattern == nil then
				dialogPacket.Reply="Hope you like it, I've given it a pattern. Oh, and you need to remove any textures before it's visible.";
				dialog:AddDialog(dialogPacket, function(dialog)
					inventory:SetValues(equippedToolID, {LockedPattern=105});

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
				dialogPacket.Reply="The tool you equipped already has a skin permanent.";
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
			gift(400, "xmaspresent")
		end)
		
		dialog:AddChoice("xmas2020", function(dialog)
			gift(200, "xmaspresent2020")
		end)
		
		dialog:AddChoice("xmas2021", function(dialog)
			gift(100, "xmaspresent2021")
		end)
	end)
	
	dialog:AddChoice("general_giftSanta");
end