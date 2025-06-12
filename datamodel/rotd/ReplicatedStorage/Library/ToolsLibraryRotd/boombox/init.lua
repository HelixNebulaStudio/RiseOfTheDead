local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local MarketplaceService = game:GetService("MarketplaceService");
local CollectionService = game:GetService("CollectionService");

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

local audioModule = game.ReplicatedStorage.Library.Audio;

local onBoomboxRemote;

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	ToolWindow = "BoomboxWindow";

	Animations={
		Core={Id=4997124843;};
		Use={Id=4997138529};
	};
	Audio={};
	Configurations={};
	Properties={};
};
--==

function toolPackage.onRequire()
	if RunService:IsClient() then return end;
	local remoteBoomboxRemote = modRemotesManager:Get("BoomboxRemote");
	local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

	onBoomboxRemote = function(player, action, siid, trackId)
		local profile = shared.modProfile:Get(player);
		local playerSave = profile and profile:GetActiveSave();
		local inventory = playerSave and playerSave.Inventory;
		local storageItem = inventory and inventory:Find(siid);
		local traderProfile = profile and profile.Trader;
		local playerGold = traderProfile and traderProfile.Gold;
		
		Debugger:Warn(`Boombox Remote`, action, siid, trackId);

		if storageItem and playerGold then
			if action == "add" then
				local assetInfo = MarketplaceService:GetProductInfo(trackId, Enum.InfoType.Asset);
				
				if assetInfo == nil then
					return 3;
				end

				if not assetInfo.IsPublicDomain then
					shared.Notify(player, "The song you tried to add is not public domain.", "Negative");
					return 3;
				end

				if playerGold < 200 then
					return 2;
				end

				local playList = inventory:GetValues(siid, "Songs") or {};
				local count = 0;
				for id, name in pairs(playList) do
					count = count +1;
					if id == trackId then
						return 4;
					end
				end

				if count >= 10 then
					return 5;
				end
				
				playList[tostring(trackId)] = assetInfo.Name:sub(1, 20);
				inventory:SetValues(siid, {Songs=playList});
				traderProfile:AddGold(-200);
				
				modAnalyticsService:Sink{
					Player=player;
					Currency=modAnalyticsService.Currency.Gold;
					Amount=200;
					EndBalance=traderProfile.Gold;
					ItemSKU=`Usage:boombox`;
				};
				return 1;
				
			elseif action == "delete" then
				local playList = inventory:GetValues(siid, "Songs") or {};
				playList[trackId] = nil;
				inventory:SetValues(siid, {Songs=playList});
				
			elseif action == "contentremoved" then
				local assetInfo = MarketplaceService:GetProductInfo(trackId, Enum.InfoType.Asset);
				
				if assetInfo and assetInfo.Name == "[ Content Deleted ]" and assetInfo.Description == "[ Content Deleted ]" then
					local playList = inventory:GetValues(siid, "Songs") or {};
					playList[trackId] = nil;
					inventory:SetValues(siid, {Songs=playList});
					
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
		if action == "contentremoved" then return end;

		return onBoomboxRemote(player, action, storageItemId, trackId);
	end
end


function toolPackage.ServerEquip(handler)
	handler.PowerTimer = nil;
end


function toolPackage.ServerUnequip(handler: ToolHandlerInstance)
	local equipmentClass: EquipmentClass = handler.EquipmentClass;
	local storageItem: StorageItem = handler.StorageItem;

	local properties = equipmentClass.Properties;

	local toolModel = handler.MainToolModel;
	if toolModel.PrimaryPart then
		local boomboxSound = toolModel.PrimaryPart:FindFirstChild("boomboxSound");
		if boomboxSound then boomboxSound:Stop(); end
		
		local boomboxParticle = toolModel.PrimaryPart:FindFirstChild("boomboxParticle");
		if boomboxParticle then boomboxParticle.Enabled = false; end
	end

	if properties.PowerTimer then
		properties.Power = math.clamp(math.ceil(properties.Power - (tick()-properties.PowerTimer)/6), 0, 100);
		storageItem:SetValues("Power", properties.Power);
	end
	properties.PowerTimer = nil;
end

function toolPackage.ActionEvent(handler: ToolHandlerInstance, packet)
	if packet.ActionIndex ~= 1 then return end;
	
	local characterClass: CharacterClass = handler.CharacterClass;

	local equipmentClass: EquipmentClass = handler.EquipmentClass;
	local toolAnimator: ToolAnimator = handler.ToolAnimator;
	local storageItem: StorageItem = handler.StorageItem;

	local siid = storageItem.ID;

	local properties = equipmentClass.Properties;

	properties.Power = storageItem:GetValues("Power") or 100;
	properties.Songs = storageItem:GetValues("Songs") or {};

	properties.IsActive = packet.IsActive == true;

	if handler.CharacterClass.ClassName == "NpcClass" then 
		if properties.IsActive then
			toolAnimator:Play("Use");
		else
			toolAnimator:Stop("Use");
		end
	end;

	local songId = packet.SongId;

	if not properties.IsActive then
		toolPackage.ServerUnequip(handler);
		return;
	end

	if characterClass.ClassName == "PlayerClass" then
		local player = (characterClass :: PlayerClass):GetInstance();

		local profile = shared.modProfile:Get(player);
		local gameSave = profile:GetActiveSave();
		local inventory = gameSave.Inventory;
			
		if properties.Power <= 0 then
			local total, itemList = inventory:ListQuantity("battery", 1);
			if itemList then
				for a=1, #itemList do
					inventory:Remove(itemList[a].ID, itemList[a].Quantity);
					shared.Notify(player, "1 Battery removed from your Inventory.", "Negative");
					properties.Power = 100;
					inventory:SetValues(siid, {Power=properties.Power});
				end
			else
				shared.Notify(player, "Boombox is out of power and you do not have a battery in your inventory.", "Negative");
				return;
			end
		end;
	end


	local soundList = {};
	for _, sound in pairs(audioModule.ServerAudio:GetChildren()) do
		if sound.TimeLength > 59 then
			table.insert(soundList, sound);
		end
	end
	

	local toolModel = handler.MainToolModel;
	local boomboxSound: Sound = toolModel.PrimaryPart:FindFirstChild("boomboxSound");
	if boomboxSound == nil then return; end;

	boomboxSound.Looped = true;

	local songName = nil;
	if songId and properties.Songs[songId] then
		boomboxSound.SoundId = "rbxassetid://"..songId;
		boomboxSound.SoundGroup = game.SoundService:FindFirstChild("InstrumentMusic");
		
		if characterClass.ClassName == "PlayerClass" then
			local player = (characterClass :: PlayerClass):GetInstance();

			boomboxSound.Loaded:Once(function()
				task.wait(0.1);
				if boomboxSound.TimeLength == 0 then
					if onBoomboxRemote then
						onBoomboxRemote(player, "contentremoved", siid, songId);
					end
					toolPackage.ServerUnequip(handler);
				end
			end)
		end

	else
		local songPicked = soundList[math.random(1, #soundList)];
		boomboxSound.SoundId = songPicked.SoundId;
		songName = songPicked:GetAttribute("OfficialName") or `"{songPicked.Name}"`;

	end
	
	
	if characterClass.ClassName == "PlayerClass" then
		local player = (characterClass :: PlayerClass):GetInstance();
		if songName then
			shared.Notify(player, "<b>Boombox Playing:</b> "..songName, "Inform");
		end

		boomboxSound:SetAttribute("SoundOwner", player.Name);
		CollectionService:AddTag(boomboxSound, "PlayerNoiseSounds");
	end

	boomboxSound:Play();
	
	local boomboxParticle = toolModel.PrimaryPart:FindFirstChild("boomboxParticle");
	if boomboxParticle then boomboxParticle.Enabled = true; end

	if properties.PowerTimer == nil then properties.PowerTimer = tick(); end;
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;