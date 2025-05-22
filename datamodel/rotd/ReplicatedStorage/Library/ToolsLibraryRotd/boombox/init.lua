local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local MarketplaceService = game:GetService("MarketplaceService");
local CollectionService = game:GetService("CollectionService");

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local remoteBoomboxRemote = modRemotesManager:Get("BoomboxRemote");

local audioModule = game.ReplicatedStorage.Library.Audio;
--==
if RunService:IsServer() then
	modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

	function onBoomboxRemote(player, action, storageItemId, trackId)
		local profile = shared.modProfile:Get(player);
		local playerSave = profile and profile:GetActiveSave();
		local inventory = playerSave and playerSave.Inventory;
		local storageItem = inventory and inventory:Find(storageItemId);
		local traderProfile = profile and profile.Trader;
		local playerGold = traderProfile and traderProfile.Gold;
		
		if storageItem and playerGold then
			if action == "add" then
				local assetInfo = MarketplaceService:GetProductInfo(trackId, Enum.InfoType.Asset);
				
				if playerGold >= 200 and assetInfo then
					if not assetInfo.IsPublicDomain then
						shared.Notify(player, "The song you tried to add is not public domain.", "Negative");
						return 3;
					end
					
					local playList = inventory:GetValues(storageItemId, "Songs") or {};
					local count = 0;
					for id, name in pairs(playList) do
						count = count +1;
						if id == trackId then
							return 4;
						end
					end
					if count < 10 then
						playList[tostring(trackId)] = assetInfo.Name:sub(1, 20);
						inventory:SetValues(storageItemId, {Songs=playList});
						traderProfile:AddGold(-200);
						
						modAnalyticsService:Sink{
							Player=player;
							Currency=modAnalyticsService.Currency.Gold;
							Amount=200;
							EndBalance=traderProfile.Gold;
							ItemSKU=`Usage:boombox`;
						};

						return 1;
					else
						return 5;
					end
				end
				
			elseif action == "delete" then
				local playList = inventory:GetValues(storageItemId, "Songs") or {};
				playList[trackId] = nil;
				inventory:SetValues(storageItemId, {Songs=playList});
				
			elseif action == "contentremoved" then
				local assetInfo = MarketplaceService:GetProductInfo(trackId, Enum.InfoType.Asset);
				
				if assetInfo and assetInfo.Name == "[ Content Deleted ]" and assetInfo.Description == "[ Content Deleted ]" then
					local playList = inventory:GetValues(storageItemId, "Songs") or {};
					playList[trackId] = nil;
					inventory:SetValues(storageItemId, {Songs=playList});
					
					traderProfile:AddGold(200);
					
					shared.Notify(player, "The song you were trying to play was removed from Roblox. You are refunded 200 gold.", "Negative");
				end
			end
		else
			Debugger:Warn("AddTrack>> Missing essentials.");
		end
		
		return 3
	end
	
	function remoteBoomboxRemote.OnServerInvoke(player, action, storageItemId, trackId)
		if action ~= "contentremoved" then
			onBoomboxRemote(player, action, storageItemId, trackId);
		end
	end
end



local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=4997124843;};
		Use={Id=4997138529};
	};
	Audio={};
	Configurations={};
	Properties={};
};

function toolPackage.OnClientUnequip()
	local player = game.Players.LocalPlayer;
	local modData = shared.require(player:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();
	
	modInterface:CloseWindow("BoomboxWindow");
end

function toolPackage.ClientItemPrompt(handler)
	local player = game.Players.LocalPlayer;
	local modData = shared.require(player:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();
	
	if modInterface:IsVisible("BoomboxWindow") then return end;
	modInterface:ToggleWindow("BoomboxWindow", nil, handler);
end

function toolPackage.ServerEquip(handler)
	handler.PowerTimer = nil;
end

function toolPackage.OnServerUnequip(handler)
	local profile = shared.modProfile:Get(handler.Player);
	local playerSave = profile:GetActiveSave();
	local inventory = playerSave.Inventory;
			
	for a=1, #handler.Prefabs do
		local prefab = handler.Prefabs[a];
		local primaryPart = prefab.PrimaryPart;
		
		if primaryPart then
			local boomboxSound = primaryPart:FindFirstChild("boomboxSound");
			if boomboxSound then boomboxSound:Stop(); end
			
			local boomboxParticle = primaryPart:FindFirstChild("boomboxParticle");
			if boomboxParticle then boomboxParticle.Enabled = false; end
		end
	end
	
	if handler.PowerTimer then
		handler.Power = math.clamp(math.ceil(handler.Power - (tick()-handler.PowerTimer)/6), 0, 100);
		inventory:SetValues(handler.StorageItem.ID, {Power=handler.Power});
	end
	handler.PowerTimer = nil;
end

function toolPackage.OnActionEvent(handler, packet)
	if packet.ActionIndex ~= 1 then return end;
	
	local profile = shared.modProfile:Get(handler.Player);
	local playerSave = profile:GetActiveSave();
	local inventory = playerSave.Inventory;
			
	local storageItem = handler.StorageItem;
	local siid = storageItem.ID;

	handler.Power = (inventory:GetValues(siid, "Power") or 100);
	handler.Songs = inventory:GetValues(siid, "Songs") or {};
	
	handler.IsActive = packet.IsActive == true;
	
	local songId = packet.SongId;

	if handler.IsActive then
		if handler.Power <= 0 then
			
			local total, itemList = inventory:ListQuantity("battery", 1);
			if itemList then
				for a=1, #itemList do
					inventory:Remove(itemList[a].ID, itemList[a].Quantity);
					shared.Notify(handler.Player, "1 Battery removed from your Inventory.", "Negative");
					handler.Power = 100;
					inventory:SetValues(siid, {Power=handler.Power});
				end
			else
				shared.Notify(handler.Player, "Boombox is out of power and you do not have a battery in your inventory.", "Negative");
				return;
			end
		end;
		
		local soundList = {};
		for _, sound in pairs(audioModule.ServerAudio:GetChildren()) do
			if sound.TimeLength > 59 then
				table.insert(soundList, sound);
			end
		end
		
		for a=1, #handler.Prefabs do
			local prefab = handler.Prefabs[a];
			
			local boomboxSound = prefab.PrimaryPart:FindFirstChild("boomboxSound");
			
			if boomboxSound then
				local songName = nil;
				if songId and handler.Songs[songId] then
					boomboxSound.SoundId = "rbxassetid://"..songId;
					boomboxSound.SoundGroup = game.SoundService:FindFirstChild("InstrumentMusic");
					
					delay(0.1, function()
						if boomboxSound.TimeLength == 0 then
							if onBoomboxRemote then
								onBoomboxRemote(handler.Player, "contentremoved", siid, songId);
							end
							toolPackage.OnServerUnequip(handler);
						end
					end)
				else
					
					local songPicked = soundList[math.random(1, #soundList)];
					boomboxSound.SoundId = songPicked.SoundId;
					songName = songPicked:GetAttribute("OfficialName") or "\""..songPicked.Name.."\"";
				end
				
				if songName then
					shared.Notify(handler.Player, "<b>Boombox Playing:</b> "..songName, "Inform");
				end
				boomboxSound:SetAttribute("SoundOwner", handler.Player and handler.Player.Name or nil);
				CollectionService:AddTag(boomboxSound, "PlayerNoiseSounds");
				boomboxSound:Play();
			end
			
			local boomboxParticle = prefab.PrimaryPart:FindFirstChild("boomboxParticle");
			if boomboxParticle then boomboxParticle.Enabled = true; end
		end
		if handler.PowerTimer == nil then handler.PowerTimer = tick(); end;
	else
		toolPackage.OnServerUnequip(handler);
		
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;