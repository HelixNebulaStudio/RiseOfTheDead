local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modCrates = require(game.ServerScriptService.ServerLibrary.Crates);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modAnalyticsService = require(game.ServerScriptService.ServerLibrary.AnalyticsService);

--== When user activates a game trigger;
return function(player, interactData, ...)
	local profile = modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local inventory = playerSave.Inventory;
	local triggerId = interactData.TriggerTag;
	
	if triggerId == "StealAtmMoney" then
		if modEvents:GetEvent(player, "bankAtm") == nil then
			modEvents:NewEvent(player, {Id="bankAtm"}, true);
			playerSave:AddStat("Money", 2000);
			shared.Notify(player, "You found $2000 in the ATM machine.", "Reward");
		else
			modEvents:SyncEvent(player, "bankAtm");
		end
		
	elseif triggerId == "VendingMachine1" then
		local event = modEvents:GetEvent(player, "VendingMachine1");
		local lastVending = event and event.Time;
		
		if lastVending == nil or modSyncTime.GetTime() >= lastVending then
			local playerMoney = playerSave:GetStat("Money");
			if playerMoney >= 500 then
				local rewardsLib = modRewardsLibrary:Find("t1Vending");
				local reward = modDropRateCalculator.RollDrop(rewardsLib, player);
				local itemId = reward[1].ItemId;
				local hasSpace = inventory:SpaceCheck{{ItemId=itemId; Data={Quantity=1;}}};
				
				modEvents:NewEvent(player, {Id="VendingMachine1"; Time=modSyncTime.GetTime()+60;}, true);
				playerSave:AddStat("Money", -500);
				modAnalytics.RecordResource(player.UserId, 500, "Sink", "Money", "Gameplay", "VendingMachine");
				
				modAnalyticsService:Sink{
					Player=player;
					Currency=modAnalyticsService.Currency.Money;
					Amount=500;
					EndBalance=playerSave:GetStat("Money");
					ItemSKU=`t1Vending`;
				};

				modAudio.Play("VendingMachine", interactData.Object);
				
				if hasSpace then
					local itemLib = modItemsLibrary:Find(itemId);
					inventory:Add(itemId, nil, function(queueEvent, storageItem)
						modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
					end);
					shared.Notify(player, "You have recieved a "..itemLib.Name..".", "Reward");
					
				else
					shared.Notify(player, "You do not have enough inventory space.", "Negative");
					
				end
				
			else
				shared.Notify(player, "You do not have enough money.", "Negative");
				
			end
		end
		
	elseif triggerId == "GumballMachine" then
		local event = modEvents:GetEvent(player, "GumballMachine");
		local timer = event and event.Time;

		if timer == nil or modSyncTime.GetTime() >= timer then
			modEvents:NewEvent(player, {Id="GumballMachine"; Time=modSyncTime.GetTime()+180;}, true);
			modAudio.Play("SuperCharge", interactData.Object);
			
			local statusList = {};
			
			table.insert(statusList, function()
				modStatusEffects.ForceField(player, 120);
				shared.Notify(player, "You recieved Forcefield for 60 seconds.", "Reward");
			end)
			
			table.insert(statusList, function()
				modStatusEffects.Reinforcement(player, 120);
				shared.Notify(player, "You recieved Reinforcement for 60 seconds.", "Reward");
			end)
			
			table.insert(statusList, function()
				modStatusEffects.Superspeed(player, 120);
				shared.Notify(player, "You recieved Superspeed for 60 seconds.", "Reward");
			end)
			
			table.insert(statusList, function()
				modStatusEffects.Lifesteal(player, 120);
				shared.Notify(player, "You recieved Lifesteal for 60 seconds.", "Reward");
			end)
			
			statusList[math.random(1, #statusList)]();
		end
		
	elseif triggerId == "Repair Satellite" then
		local mission = modMission:Progress(player, 11);
		if mission and mission.ProgressionPoint == 1 then
			
			local quantity = 0;
			local itemsList = profile.ActiveInventory:ListByItemId("metal");
			for a=1, #itemsList do quantity = quantity +itemsList[a].Quantity; end
			
			local requiredQuantity = mission.Redo and 1 or 100;
			if quantity >= requiredQuantity then
				local storageItem = inventory:FindByItemId("metal");
				inventory:Remove(storageItem.ID, requiredQuantity);
				modMission:Progress(player, 11, function(mission)
					mission.ProgressionPoint = 2;
				end)
				shared.Notify(player, requiredQuantity.." Metal Scraps removed from your Inventory.", "Negative");
				interactData:Sync(player, {CanInteract=false; Label="Satellite is fixed now.";});
				modAudio.Play("Repair", interactData.Object);
			else
				shared.Notify(player, "Not enough Metal Scraps, need "..math.clamp(requiredQuantity-quantity, 0, requiredQuantity).." more.", "Negative");
			end
		end
		
	elseif triggerId == "Repair TSLift" and modEvents:GetEvent(player, "lift1Shortcut") == nil then
		local item, storage = modStorage.FindItemIdFromStorages("circuitboards", player);
		if item then
			storage:Remove(item.ID);
			shared.Notify(player, "A circuit board has been removed from your Inventory.", "Negative");
			interactData:Sync(player, {CanInteract=false; Label=nil;});
			modAudio.Play("Repair", interactData.Object);
			if modEvents:GetEvent(player, "lift1Shortcut") == nil then
				modEvents:NewEvent(player, {Id="lift1Shortcut"}, true);
			else
				modEvents:SyncEvent(player, "lift1Shortcut");
			end
		else
			shared.Notify(player, "You do not have a circuit board to repair this.", "Negative");
		end
	
	elseif triggerId == "Repair TunnelSpotlight" and modEvents:GetEvent(player, "secretSpotlightFix") == nil then
		local item, storage = modStorage.FindItemIdFromStorages("lightbulb", player);
		if item then
			storage:Remove(item.ID);
			shared.Notify(player, "A light bulb has been removed from your Inventory.", "Negative");
			interactData:Sync(player, {CanInteract=false; Label=nil;});
			modAudio.Play("Repair", interactData.Object);
			if modEvents:GetEvent(player, "secretSpotlightFix") == nil then
				modEvents:NewEvent(player, {Id="secretSpotlightFix"}, true);
			else
				modEvents:SyncEvent(player, "secretSpotlightFix");
			end
		else
			shared.Notify(player, "You do not have a light bulb to repair this.", "Negative");
		end
	
	elseif triggerId == "UnlockCamoPack" then
		if profile.SkinsPacks.Camo == nil then
			profile:Unlock("SkinsPacks", "Camo", true);
		end

	elseif triggerId == "UnlockHalloweenPack" then
		if profile.SkinsPacks.Halloween == nil then
			profile:Unlock("SkinsPacks", "Halloween", true);
		end
		
	elseif triggerId == "miaSpawn" then
		if modMission:Progress(player, 24) and modMission:Progress(player, 24).ProgressionPoint == 4 then
			modMission:Progress(player, 24, function(mission)
				if mission.ProgressionPoint == 4 then mission.ProgressionPoint = 5; end;
			end)
		end
		
	elseif triggerId == "Push Mall Shelf" then
		local s, e = pcall(function()
			if interactData.CanInteract ~= false then
				interactData.CanInteract = false;
				interactData.Label = "";
				interactData:Sync();
				
				local ventInteractable = require(workspace.Interactables.ventSecretEntrance.Interactable);
				ventInteractable.CanInteract = true;
				ventInteractable.Label = "Enter Vent";
				ventInteractable.Script = workspace.Interactables.ventSecretEntrance.Interactable;
				ventInteractable:Sync();
				
				interactData.Object.Size = Vector3.new(0, 0, 0);
				local shelfObj = workspace.Environment.MoveableShelf;
				TweenService:Create(shelfObj, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
					CFrame = CFrame.new(790.140137, 95.0486832, -631.332397, -0.669129193, 0, 0.743146181, 0, 1, 0, -0.743146181, 0, -0.669129193);
				}):Play();
				
				delay(20, function()
					interactData.CanInteract = true;
					interactData.Label = nil;
					interactData:Sync();
					
					ventInteractable.CanInteract = false;
					ventInteractable.Label = "Blocked by the shelf..";
					ventInteractable:Sync();
				
					interactData.Object.Size = Vector3.new(0.4, 4.51, 1.38);
					TweenService:Create(shelfObj, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
						CFrame = CFrame.new(792.342407, 95.0486832, -633.315308, 0, 0, 1, 0, 1, -0, -1, 0, 0);
					}):Play();
				end)
			end
		end)
		if not s then Debugger:Warn(e) end;
		
	elseif triggerId == "MallKeypad" then
		local codeEntered = ...;
		if codeEntered == "240" then
			local exist = false;
			for a=1, #profile.Junk.CacheInstances do
				if profile.Junk.CacheInstances[a] and profile.Junk.CacheInstances[a].Name == "Mall's Gift" then
					exist = true;
				end
			end
			
			shared.Notify(player, "[Keypad] Code accepted.", "Positive");
			if not exist then
				local content = {};
				if modEvents:GetEvent(player, "mallGift") == nil then
					content = modCrates.GenerateRewards("mallGift");
					modEvents:NewEvent(player, {Id="mallGift"});
				end
				
				table.insert(profile.Junk.CacheInstances, (modCrates.Spawn("mallGift", CFrame.new(702.059998, 10.0209656, -693.022827, -1, 0, 0, 0, 1, 0, 0, 0, -1), {player}, content, true)));
				shared.Notify(player, "You found a Mall's Gift from the safe.", "Reward");
			end
		else
			shared.Notify(player, "[Keypad] Code rejected.", "Negative");
		end
		
	elseif triggerId == "clinicKeycard" then
		if modEvents:GetEvent(player, "clinicSecretKeycard") == nil then
			modEvents:NewEvent(player, {Id="clinicSecretKeycard"});
			shared.Notify(player, "You found a keycard.", "Reward");

		else
			modEvents:SyncEvent(player, "clinicSecretKeycard");
		end
		
	elseif triggerId == "Climb Vent Ladder" then
		local mission = modMission:GetMission(player, 33);
		if mission.Type == 2 and mission.ProgressionPoint > 2 then
			modServerManager:Travel(player, "AwokenTheBear");
		end
		
	elseif triggerId == "ForfeitMission33" then
		modMission:FailMission(player, 33, "You left Stan behind..");
		task.wait(2);
		modServerManager:Travel(player, "TheMall");
		
	elseif triggerId == "SpikingUp:Add" then
		local subId = interactData.SubId;
		if subId == nil then Debugger:Warn("SpikingUp:Add>>  Missing sub id."); return end;
		local mission = modMission:Progress(player, 39);
		if mission and mission.ObjectivesCompleted[subId] ~= true then
			local build = false;
			
			local quantity = 0;
			local itemsList = profile.ActiveInventory:ListByItemId("wood");
			for a=1, #itemsList do quantity = quantity +itemsList[a].Quantity; end
			
			if quantity >= 20 then
				local storageItem = inventory:FindByItemId("wood");
				inventory:Remove(storageItem.ID, 20);
				shared.Notify(player, "20 Wooden Parts removed from your Inventory.", "Negative");
				
				build = true;
			else
				shared.Notify(player, "Not enough Wooden Parts, need "..math.clamp(quantity, 0, 20).."/20 more.", "Negative");
			end
			
			if build then
				modMission:Progress(player, 39, function(mission)
					mission.ObjectivesCompleted[subId] = true;
				end)
				
				local wallObjects = interactData.Object and interactData.Object:FindFirstChild("Objects");
				local interactables = interactData.Object and interactData.Object:FindFirstChild("Interactables");
				
				if interactables then 
					modReplicationManager.ReplicateIn(player, interactables, workspace.Interactables);
				end;
				modReplicationManager.ReplicateIn(player, wallObjects, workspace.Environment);
				local parts = wallObjects and wallObjects:GetDescendants();
				for a=1, #parts do
					if parts[a]:IsA("BasePart") then
						parts[a].CanCollide = true;
						parts[a].Transparency = 0;
					end
				end
				if wallObjects and wallObjects.PrimaryPart then
					modAudio.Play("Repair", wallObjects.PrimaryPart);
				end
				interactData.Object:Destroy();
			end
		else
			shared.Notify(player, "That is already built.", "Negative");
		end
		
	elseif triggerId == "Push Statue" then
		modMission:Progress(player, 40, function(mission)
			local statueObject = mission.Cache.Statue;
			
			if statueObject then
				interactData.CanInteract = false;
				interactData.Label = "";
				interactData:Sync();
				interactData.Object.Size = Vector3.new(0, 0, 0);
				if mission.ProgressionPoint == 3 then mission.ProgressionPoint = 4; end;
				
				TweenService:Create(statueObject, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
					CFrame = CFrame.new(352.495, -30.669, 1923.279);
				}):Play();
				
				delay(30, function()
					interactData.CanInteract = true;
					interactData.Label = nil;
					interactData:Sync();
					
					interactData.Object.Size = Vector3.new(0.4, 4.51, 1.38);
					TweenService:Create(statueObject, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
						CFrame = CFrame.new(352.49469, -30.6694565, 1912.8186, 1, 0, 0, 0, 1, 0, 0, 0, 1);
					}):Play();
				end)
			else
				Debugger:Warn("Statue does not exist.");
			end
		end)
		
	elseif triggerId == "Tombs NekronMask" then
		profile:UnlockCollectible("nm");
		if modEvents:GetEvent(player, "takeNekronMask") == nil then
			local hasSpace = inventory:SpaceCheck{{ItemId="nekronmask"; Data={Quantity=1;}}};
			if hasSpace then
				inventory:Add("nekronmask");
				modEvents:NewEvent(player, {Id="takeNekronMask"});
				shared.Notify(player, "You picked up a Nekron Mask.", "Reward");
				game.Debris:AddItem(interactData.Object, 0);
			else
				
				shared.Notify(player, "Inventory full!", "Negative");
			end
			
		end
		
		modMission:Progress(player, 40, function(mission)
			if mission.ProgressionPoint < 7 then mission.ProgressionPoint = 7; end;
		end)
		
	elseif triggerId == "Summon JackReap" then

		local equippedTool = profile.EquippedTools.ID;
		local storageItem = inventory and inventory:Find(equippedTool) or nil;
		if storageItem and storageItem.ItemId == "voodoodoll" then

			local hasSpace = inventory:SpaceCheck{{ItemId="jacksscythe"; Data={Quantity=1;}}};
			if hasSpace then
				modMission:Progress(player, 43, function(mission)
					if mission.ProgressionPoint < 5 then mission.ProgressionPoint = 5; end;
					game.Debris:AddItem(interactData.Object, 0);
				end)
				shared.Notify(player, "You hear a creepy sound behind you..", "Inform");
				
			else
				shared.Notify(player, "Inventory full!", "Negative");
				
			end
			
		else
			shared.Notify(player, "Voodoo Doll has to be equipped!", "Negative");
			
		end
		
	elseif triggerId == "HarborGiftSand" then
		local equippedItemId = profile.EquippedTools.ItemId;
		if equippedItemId == "shovel" then
			if modEvents:GetEvent(player, "HarborGiftSand") == nil then
				modEvents:NewEvent(player, {Id="HarborGiftSand"}, true);
				modReplicationManager.UnreplicateFrom(player, interactData.Object.Parent);
				
			else
				modEvents:SyncEvent(player, "HarborGiftSand");
				
			end
			
		else
			shared.Notify(player, "Shovel has to be equipped!", "Negative");
			
		end
		
	elseif triggerId == "HarborGiftEntrance" and modEvents:GetEvent(player, "HarborGiftSand") then
		local enter = false;
		
		if modEvents:GetEvent(player, "HarborGiftEntrance") == nil then
			local quantity = 0;
			local itemsList = profile.ActiveInventory:ListByItemId("cultistkey1");
			for a=1, #itemsList do quantity = quantity +itemsList[a].Quantity; end

			if quantity >= 1 then
				local storageItem = inventory:FindByItemId("cultistkey1");
				inventory:Remove(storageItem.ID, 1);
				modEvents:NewEvent(player, {Id="HarborGiftEntrance"});
				enter  = true;
				
				modAudio.Play("HeavySplash", interactData.Object).PlaybackSpeed = 2;
			else
				shared.Notify(player, "Shovel has to be equipped!", "Negative");
			end
		else
			profile:UnlockItemCodex("cultistkey1");
			enter = true;
		end
		if enter then
			local interactObject = interactData.Object;
			local destination = interactObject.Destination;
			
			local tpCframe = CFrame.new(destination.WorldPosition + Vector3.new(0, 2.35, 0)) * CFrame.Angles(0, math.rad(destination.WorldOrientation.Y-90), 0);
			shared.modAntiCheatService:Teleport(player, tpCframe)
			
			local exist = false;
			for a=1, #profile.Junk.CacheInstances do
				if profile.Junk.CacheInstances[a] and profile.Junk.CacheInstances[a].Name == "Harbor's Gift" then
					exist = true;
				end
			end
			
			if not exist then
				local content = {};
				if profile.Flags:Get("harborGift") == nil then
					content = modCrates.GenerateRewards("harborGift");
					profile.Flags:Add{Id="harborGift"};
				end
				
				table.insert(profile.Junk.CacheInstances, (modCrates.Spawn("harborGift", CFrame.new(-520.727661, -68.5934601, 437.814148, -1, 0, 0, 0, 1, 0, 0, 0, -1), {player}, content, true)));
			end
			
			modAudio.Play("HeavyMetalDoor", interactObject.Destination).PlaybackSpeed = 0.5;
		end
		

	elseif triggerId == "EB2_LightBarrel" then
		local mission = modMission:Progress(player, 50);
		if mission and mission.ProgressionPoint == 5 then
			modMission:Progress(player, 50, function(mission)
				mission.ProgressionPoint = 6;
			end)
		end
		
	elseif triggerId == "WinterTreelumSapling" then
		
		local interactObject = interactData.Object;
		local spawnPosition = interactObject.Position;
		
		if workspace.Entity:FindFirstChild("Winter Treelum") == nil then
			modNpc.Spawn("Winter Treelum", CFrame.new(spawnPosition) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0));
			shared.Notify(game.Players:GetPlayers(), "A Winter Treelum has been awokened.", "Important");
			
			game.Debris:AddItem(interactData.Object.Parent, 0);
		else
			shared.Notify(player, "Winter Treelum can not be summoned at the moment.", "Negative");
			
			
		end
		
		
	end
end;
