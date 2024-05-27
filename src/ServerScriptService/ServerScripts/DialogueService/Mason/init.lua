local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage); 
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");

local npcName = script.Name;
return function(player, dialog, data)
	local npcModule = dialog:GetNpcModule();
	
	local activeMissionCount = #modMission:GetNpcMissions(player, script.Name);
	local profile = shared.modProfile:Get(player);
	local playerSave = profile:GetActiveSave();

	local perkCupcakes = modEvents:GetEvent(player, "perkCupcakes");
	
	if perkCupcakes and perkCupcakes.Remaining > 0 then
		local dialogPacket = {
			Face="Happy";
			Dialogue="Can I have a cupcake?";
		}

		local inventory = playerSave.Inventory;
		local hasSpace = inventory:SpaceCheck{
			{ItemId="perkscupcake"; Data={Quantity=1}; };
		};

		if hasSpace then
			dialogPacket.Reply="Sure, here you go.";
			
		else
			dialogPacket.Reply="You're going to need more space in your inventory.";
			
		end
		
		dialog:AddDialog(dialogPacket, function(dialog)
			if not hasSpace then return end;
			
			inventory:Add("perkscupcake", {Quantity=1;}, function(queueEvent, storageItem)
				modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
			end);

			perkCupcakes.Remaining = perkCupcakes.Remaining -1;
			shared.Notify(player, "You recieved a Perks Cupcake from Mason. Remaining: "..(perkCupcakes.Remaining), "Reward");

			modEvents:NewEvent(player, perkCupcakes);
			
			task.spawn(function()
				local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
				modAnalytics:ReportError("Mason", "Cupcake claimed");
			end)
		end);
	end

	local hardhatsilver = modEvents:GetEvent(player, "freeHardhatsilver");
	if hardhatsilver == nil and profile.GamePass.DbTinker then
		dialog:SetInitiate("Hey $PlayerName, I have something for you.");

		local dialogPacket = {
			Face="Happy";
			Dialogue="What is it?";
		}

		local inventory = playerSave.Inventory;
		local hasSpace = inventory:SpaceCheck{
			{ItemId="hardhatsilver"; Data={Quantity=1}; };
		};

		if hasSpace then
			dialogPacket.Reply="Sure, here you go.";
		else
			dialogPacket.Reply="You're going to need more space in your inventory.";
		end

		dialog:AddDialog(dialogPacket, function(dialog)
			if not hasSpace then return end;

			inventory:Add("hardhatsilver", {Quantity=1;}, function(queueEvent, storageItem)
				modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
			end);
			shared.Notify(player, "You recieved a Hard Hat Silver from Mason for unlocking Tinkering Commands achievement.", "Reward");
			modEvents:NewEvent(player, {Id="freeHardhatsilver"});
		end);
	end
	
	if modMission:Progress(player, 54) then return end;
	if modMission:IsComplete(player, 2) then
		
		if modBranchConfigs.IsWorld("Safehome") then
			if modMission:IsComplete(player, 54) then
				dialog:AddChoice("guide_safehomeNpcs");
				dialog:AddChoice("guide_safehomeSustain");

				if activeMissionCount <= 0 then 
					remoteSetHeadIcon:FireClient(player, 1, npcName, "Guide");
				end
			end
			
		else
			dialog:AddChoice("general_what");
			dialog:AddChoice("general_where");
			dialog:AddChoice("general_how");
			
			dialog:AddChoice("guide_refillAmmo");
			dialog:AddChoice("guide_makeMoney");
			dialog:AddChoice("guide_getWeapon");
			dialog:AddChoice("guide_getPerks");
			dialog:AddChoice("guide_invSpace");
			dialog:AddChoice("guide_getMaterials");
			dialog:AddChoice("guide_levelUp");

			if activeMissionCount <= 0 then 
				remoteSetHeadIcon:FireClient(player, 1, npcName, "Guide");
			end;
		end
		
	end
	
	if npcModule.CarLooping then
		dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
	end
end
