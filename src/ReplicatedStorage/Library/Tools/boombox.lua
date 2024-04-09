local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");
local MarketplaceService = game:GetService("MarketplaceService");
local CollectionService = game:GetService("CollectionService");
local audioModule = game.ReplicatedStorage.Library.Audio;

local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local remoteBoomboxRemote = modRemotesManager:Get("BoomboxRemote");

local onBoomboxRemote;

if RunService:IsServer() then
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
	modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
	
	function onBoomboxRemote(player, action, storageItemId, trackId)
		local profile = modProfile:Get(player);
		local playerSave = profile and profile:GetActiveSave();
		local inventory = playerSave and playerSave.Inventory;
		local storageItem = inventory and inventory:Find(storageItemId);
		local traderProfile = profile and profile.Trader;
		local playerGold = traderProfile and traderProfile.Gold;
		
		if storageItem and playerGold then
			if action == "add" then
				local assetInfo = MarketplaceService:GetProductInfo(trackId, Enum.InfoType.Asset);
				
				if playerGold >= 200 and assetInfo then --3213444026
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
						modAnalytics.RecordResource(player.UserId, 200, "Sink", "Gold", "Usage", "boombox");
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
					modAnalytics.RecordResource(player.UserId, 200, "Source", "Gold", "Usage", "boombox");
					
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

return function()
	local Tool = {};
	Tool.IsActive = false;
	
	function Tool:OnEquip()
		self.PowerTimer = nil;
	end
	
	function Tool:OnUnequip()
		local profile = modProfile:Get(self.Player);
		local playerSave = profile:GetActiveSave();
		local inventory = playerSave.Inventory;
				
		for a=1, #self.Prefabs do
			local prefab = self.Prefabs[a];
			local primaryPart = prefab.PrimaryPart;
			
			if primaryPart then
				local boomboxSound = primaryPart:FindFirstChild("boomboxSound");
				if boomboxSound then boomboxSound:Stop(); end
				
				local boomboxParticle = primaryPart:FindFirstChild("boomboxParticle");
				if boomboxParticle then boomboxParticle.Enabled = false; end
			end
		end
		
		if self.PowerTimer then
			self.Power = math.clamp(math.ceil(self.Power - (tick()-self.PowerTimer)/6), 0, 100);
			inventory:SetValues(self.StorageItem.ID, {Power=self.Power});
		end
		self.PowerTimer = nil;
	end
	
	function Tool:ClientUnequip()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule"));
		local modInterface = modData:GetInterfaceModule();
		
		modInterface:CloseWindow("BoomboxWindow");
	end
	
	function Tool:ClientItemPrompt()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule"));
		local modInterface = modData:GetInterfaceModule();
		
		if modInterface:IsVisible("BoomboxWindow") then return end;
		wait(0.1);
		modInterface:ToggleWindow("BoomboxWindow", self.StorageItem, self);
	end
	
	function Tool:OnPrimaryFire(isActive, songId)
		local profile = modProfile:Get(self.Player);
		local playerSave = profile:GetActiveSave();
		local inventory = playerSave.Inventory;
				
		self.Power = (inventory:GetValues(self.StorageItem.ID, "Power") or 100);
		self.Songs = inventory:GetValues(self.StorageItem.ID, "Songs") or {};
		
		self.IsActive = isActive;
		
		if self.IsActive then
			if self.Power <= 0 then
				
				local total, itemList = inventory:ListQuantity("battery", 1);
				if itemList then
					for a=1, #itemList do
						inventory:Remove(itemList[a].ID, itemList[a].Quantity);
						shared.Notify(self.Player, "1 Battery removed from your Inventory.", "Negative");
						self.Power = 100;
						inventory:SetValues(self.StorageItem.ID, {Power=self.Power});
					end
				else
					shared.Notify(self.Player, "Boombox is out of power and you do not have a battery in your inventory.", "Negative");
					return;
				end
			end;
			
			local soundList = {};
			for _, sound in pairs(audioModule:GetChildren()) do
				if sound.TimeLength > 59 then
					table.insert(soundList, sound);
				end
			end
			
			for a=1, #self.Prefabs do
				local prefab = self.Prefabs[a];
				
				local boomboxSound = prefab.PrimaryPart:FindFirstChild("boomboxSound");
				
				if boomboxSound then
					local songName = nil;
					if songId and self.Songs[songId] then
						boomboxSound.SoundId = "rbxassetid://"..songId;
						boomboxSound.SoundGroup = game.SoundService:FindFirstChild("InstrumentMusic");
						
						delay(0.1, function()
							if boomboxSound.TimeLength == 0 then
								if onBoomboxRemote then
									onBoomboxRemote(self.Player, "contentremoved", self.StorageItem.ID, songId);
								end
								Tool.OnUnequip(self);
							end
						end)
					else
						
						local songPicked = soundList[math.random(1, #soundList)];
						boomboxSound.SoundId = songPicked.SoundId;
						songName = songPicked:GetAttribute("OfficialName") or "\""..songPicked.Name.."\"";
					end
					
					if songName then
						shared.Notify(self.Player, "<b>Boombox Playing:</b> "..songName, "Inform");
					end
					boomboxSound:SetAttribute("SoundOwner", self.Player and self.Player.Name or nil);
					CollectionService:AddTag(boomboxSound, "PlayerNoiseSounds");
					boomboxSound:Play();
				end
				
				local boomboxParticle = prefab.PrimaryPart:FindFirstChild("boomboxParticle");
				if boomboxParticle then boomboxParticle.Enabled = true; end
			end
			if self.PowerTimer == nil then self.PowerTimer = tick(); end;
		else
			Tool.OnUnequip(self);
			
		end
		
	end
	
	return Tool;
end;