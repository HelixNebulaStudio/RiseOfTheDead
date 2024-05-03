local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local random = Random.new();

--== Variables;
local SaveData = {
	TradingService=nil;
};
SaveData.__index = SaveData;

local BadgeService = game:GetService("BadgeService");

local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);
local modSkillTreeLibrary = require(game.ReplicatedStorage.Library.SkillTreeLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modAchievementLibrary = require(game.ReplicatedStorage.Library.AchievementLibrary);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);
local modDialogues = require(game.ServerScriptService.ServerLibrary.DialogueSave);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modWorkbenchData = require(game.ServerScriptService.ServerLibrary.WorkbenchData);
local modAppearanceData = require(game.ServerScriptService.ServerLibrary.AppearanceData);
local modStatisticProfile = require(game.ServerScriptService.ServerLibrary.StatisticProfile);
local modStatusSave = require(game.ServerScriptService.ServerLibrary.StatusSave);
local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));

local remoteMasterySync = modRemotesManager:Get("MasterySync");
local remoteHudNotification = modRemotesManager:Get("HudNotification");

local libAuthTree = modSkillTreeLibrary.Authority:GetSorted();
local libEnduTree = modSkillTreeLibrary.Endurance:GetSorted();
local libSyneTree = modSkillTreeLibrary.Synergy:GetSorted();

--== Script;
function SaveData.new(profile)
	local player = profile.Player;
	
	local dataMeta = setmetatable({}, SaveData);
	dataMeta.__index = dataMeta;
	
	dataMeta.Profile = profile;
	dataMeta.Player = player;
	dataMeta.Title = "Main Save";
	dataMeta.Statistics = modStatisticProfile.new(player);
	dataMeta.FirstSync = false;
	
	local data = setmetatable({}, dataMeta);
	dataMeta.Sync = function(self, hierarchyKey)
		--if self.FirstSync == false then return end;
		
		if hierarchyKey == nil then
			profile:Sync("GameSave/Missions");
			profile:Sync("GameSave/Stats");
			profile:Sync("GameSave/Mailbox");
			
		else
			profile:Sync("GameSave"..(hierarchyKey and "/"..hierarchyKey or ""));
			
		end
		
	end;
	dataMeta.AppearanceData = modAppearanceData.new(player, data);
	
	local saveTime = os.time();
	data.LastSave = saveTime;
	data.LoadVersion = "";
	data.Version = modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild;
	data.Spawn = "warehouse";
	data.Gps = "";
	
	data.LastHealth = 10;
	data.LastFastTravel = 0;
	data.Stats = {
		Money = random:NextInteger(15,30);
	};
	
	data.Missions = modMission.NewList(profile, function() data:Sync("Missions") end);
	data.ActiveDailyMissionId = 0;
	
	data.Masteries = {};
	data.Inventory = modStorage.new("Inventory", "Inventory", 30, player);
	data.Inventory.PremiumStorage = 20;
	
	data.Clothing = modStorage.new("Clothing", "Clothing", 5, player);
	data.Clothing:ConnectCheck(function(packet)
		local dragStorageItem = packet.DragStorageItem;
		local targetStorageItem = packet.TargetStorageItem;
		
		if packet.DragStorage == data.Clothing then 
			packet.Allowed = true;
			return packet;
		end;
		if targetStorageItem and dragStorageItem.ItemId == targetStorageItem.ItemId then 
			packet.Allowed = true;
			return packet
		end; -- true if swapping with item of same id
		
		if dragStorageItem then
			if dragStorageItem.Properties.Type == modItemsLibrary.Types.Clothing then
				local clothingLibA = modClothingLibrary:Find(dragStorageItem.ItemId);
				local groupSetting = modClothingLibrary.GroupSettings[clothingLibA.GroupName];
				
				local denyMsg;
				
				data.Clothing:Loop(function(containerItem)
					local itemLib = containerItem.Properties;
					local clothingLibB = modClothingLibrary:Find(containerItem.ItemId);
					
					if dragStorageItem.ItemId == containerItem.ItemId then
						denyMsg = "You are already wearing a "..itemLib.Name.."!";
						return true;
						
					elseif clothingLibA.GroupName == clothingLibB.GroupName then
						if groupSetting and groupSetting.Overlappable == false then
							denyMsg = "Take off the "..itemLib.Name.." first!";
							return true;
						end
						
					end
					return;
				end)
				
				if denyMsg ~= nil then
					packet.Allowed = false;
					packet.FailMsg = denyMsg;
					return packet;
				end;
				
				packet.Allowed = true;
				return packet;
			end

			packet.FailMsg = "Item "..dragStorageItem.ItemId.." is not allowed in clothing storage.";
		end
		
		packet.Allowed = false;
		return packet;
	end)
	data.Clothing.OnChanged:Connect(function()
		dataMeta.AppearanceData:Update(data.Clothing);
	end)
	
	data.Wardrobe = modStorage.new("Wardrobe", "Wardrobe", 50, player);
	data.Wardrobe.PremiumStorage = 30;
	data.Wardrobe:ConnectCheck(function(packet)
		local dragStorageItem = packet.DragStorageItem;
		local targetStorageItem = packet.TargetStorageItem;
		
		if packet.DragStorage == data.Wardrobe then packet.Allowed = true; return packet; end;
		if targetStorageItem and dragStorageItem.ItemId == targetStorageItem.ItemId then packet.Allowed = true; return packet; end;
		if dragStorageItem then
			if dragStorageItem.Properties.Type == modItemsLibrary.Types.Clothing then
				packet.Allowed = true;
				return packet;
			end
			packet.FailMsg = "Item "..dragStorageItem.ItemId.." is not allowed in wardrobe storage.";
		end
		
		packet.Allowed = false;
		return packet;
	end)
	--Adding new storages requires adding sync in inv interface;
	
	data.Blueprints = modBlueprints.new(player, function() data:Sync("Blueprints") end);
	data.Dialogues = modDialogues.new(player);
	data.Storages = {};
	data.Events = modEvents.new(player);
	data.Mailbox = {};
	data.Workbench = modWorkbenchData.new(player, function() data:Sync("Workbench") end);
	data.Achievements = {};
	data.StatusSave = modStatusSave.new(player);
	
	local moddedSelf = modModEngineService:GetServerModule(script.Name);
	if moddedSelf then
		moddedSelf:OnNewSave(SaveData, data);
	end
	
	dataMeta.__newindex = function(self, key, value) if rawget(data, key) == nil then dataMeta[key] = value; end; end;
	return data;
end

function SaveData:Load(rawData, isPrimarySave)
	rawData = rawData or {};
	
	for key, value in pairs(self) do
		local data = rawData[key] or self[key];
		
		if self[key] ~= nil then

			if key == "Stats" then
				for k, v in pairs(data) do
					if k == "Perks" or k == "Money" then
						self.Stats[k] = math.clamp(v, 0, math.huge);
					elseif k:match("Kills") and k:match("LevelKills-") == nil and k ~= "Kills" and k ~= "ZombieKills" and k ~= "HumanKills" then
						--self.Statistics:SetStat("KillTracker", k, v);
					else
						self.Stats[k] = v;
					end
				end
				
			elseif key == "Storages" then
				for id, rawStorage in pairs(data) do
					if id == "Safehouse Storage" then
						id = "Safehouse";
					end
					if id == "Inventory" then
						rawStorage.Name = "Inventory";
					elseif id == "Safehouse" then
						rawStorage.Name = "Safehouse Storage";
					end
					
					local newStorage = modStorage.new(id, (rawStorage.Name or id), rawStorage.Size, self.Player):Load(rawStorage);
					newStorage:InitStorage();

					local items = newStorage:Loop();
					if items > 0 or rawStorage.Expandable or (rawStorage.Values and next(rawStorage.Values)) then -- This saves upgraded storages and ignores empty storages.
						self.Storages[id] = newStorage;
					end
				end
				
			elseif typeof(self[key]) == "table" and self[key].Load then
				self[key] = self[key]:Load(data);
				
			elseif key == "LoadVersion" or key == "Version" then
			else
				self[key] = data;
			end
		end
	end
	
	if rawData.Version then
		self.LoadVersion = rawData.Version;
		
		if self.LoadVersion ~= self.Version then
			self.Events:Remove("seenupdatelog");
		end
	end
	
	if self.Stats and self.Stats.Level then
		self.Stats.Level = math.clamp(self.Stats.Level, 0, modGlobalVars.MaxLevels);
		local focusLevel = modGlobalVars.GetLevelToFocus(self.Stats.Level);
		for a=0, focusLevel-5 do
			if self.Stats["LevelKills-"..a] then
				self.Stats["LevelKills-"..a] = nil;
			end
		end
	end
	
	local moddedSelf = modModEngineService:GetServerModule(script.Name);
	if moddedSelf then
		moddedSelf:OnLoadSave(SaveData, self);
		
	else
		--==
		if rawData.Version == nil then 
			
		elseif rawData.Version == "1.3.9" then
			local function removeOwners(storageItem)
				if storageItem.Values then
					if storageItem.Values.Owner then
						storageItem.Values.Owner = nil;
					end
					if storageItem.Values.OwnersList then
						storageItem.Values.OwnersList = nil;
					end
				end
			end

			self.Inventory:Loop(removeOwners);
			for id, _ in pairs(self.Storages) do
				self.Storages[id]:Loop(removeOwners);
			end

		elseif rawData.Version == "1.5.8.63" then
			Debugger:Log("Converting save from 1.5.8.63..");

			local function updateItem(storageItem)
				local modItemSkinWear = require(game.ReplicatedStorage.Library.ItemSkinWear);
				modItemSkinWear.Generate(self.Player, storageItem, "setideal");
			end

			self.Inventory:Loop(updateItem);
			for id, _ in pairs(self.Storages) do
				self.Storages[id]:Loop(updateItem);
			end

		end

		if rawData.Version == "1.6.1.48" then
			local m58EventObj = self.Events:Get("mission58choice");
			if m58EventObj then
				if m58EventObj.Value == true or self.Missions:Get(62) then
					m58EventObj.Rats = true;
				end
				if m58EventObj.Value == false or self.Missions:Get(63) then
					m58EventObj.Bandits = true;
				end
				
			end
		end
		
		local codexEvent = self.Events:Get("itemCodex1");
		if codexEvent == nil then
			task.spawn(function()
				for _, storage in pairs(modStorage.GetPrivateStorages(self.Player)) do
					storage:Loop(function(storageItem)
						self.Profile:UnlockItemCodex(storageItem.ItemId, false);
					end);
				end
				self.Profile:UnlockItemCodex(nil, true);
			end)
			self.Events:Add({Id="itemCodex1"});
		end

		local skinPermUpdate = self.Events:Get("skinPermUpdate1");
		if skinPermUpdate == nil then
			self.Events:Add({Id="skinPermUpdate1"});

			local function updateItem(storageItem)
				local itemId = storageItem.ItemId;
				local itemUnlockables = self.Profile.ItemUnlockables;

				local unlockedSkins = {};

				-- Clothing
				local oldItemUnlockables = itemUnlockables[itemId];
				for skinId, _ in pairs(oldItemUnlockables) do
					table.insert(unlockedSkins, skinId);
				end

				-- Tools
				if storageItem:GetValues("LockedPattern") then
					table.insert(unlockedSkins, storageItem:GetValues("LockedPattern"));
					storageItem:SetValues("ActiveSkin", unlockedSkins[#unlockedSkins]);
				end

				if storageItem:GetValues("ItemUnlock") then
					storageItem:SetValues("ActiveSkin", storageItem:GetValues("ItemUnlock"));
				end

				storageItem:SetValues("Skins", unlockedSkins);
			end

			self.Inventory:Loop(updateItem);
			self.Clothing:Loop(updateItem);
			self.Wardrobe:Loop(updateItem)
			for id, _ in pairs(self.Storages) do
				self.Storages[id]:Loop(updateItem);
			end
		end
	end
	
	return self;
end

function SaveData:GetStat(key)
	return self.Stats[key] or 0;
end

function SaveData:SetStat(key, value)
	self.Stats[key] = value;
	
	self:Sync("Stats/"..key);
end

function SaveData:AddStat(key, amount, force)
	if modBranchConfigs.CurrentBranch.Name == "Live" then
		if key == "Money" and self.Stats.Money and self.Stats.Money >= modGlobalVars.MaxMoney and amount > 0 and force ~= true then
			amount = 0;
		end
		if key == "Perks" and self.Stats.Perks and self.Stats.Perks >= modGlobalVars.MaxPerks and amount > 0 and force ~= true then
			amount = 0;
		end 
		if key == "TweakPoints" and self.Stats.TweakPoints and self.Stats.TweakPoints >= modGlobalVars.MaxTweakPoints and amount > 0 and force ~= true then
			amount = 0;
		end 
	end
	
	self.Stats[key] = (self.Stats[key] or 0) + amount;
	
	if key == "Money" or key == "Perks" then
		
		if SaveData.TradingService then
			SaveData.TradingService:RefreshSessions(self.Player.Name);
		end
		
		if amount ~= 0 then
			self.Profile.Analytics:Log(key, amount);
			self.Statistics:AddStat("Resources", key..(amount > 0 and "-Gain" or "-Loss"), amount);
		end
		
	elseif key == "Kills" then
		self.Stats.Kills = (self.Stats.ZombieKills or 0) + (self.Stats.HumanKills or 0);
		
	elseif key == "ZombieKills" then
		local amt = self.Stats[key];
		if amt >= 1000 then
			self:AwardAchievement("thedef");
		end
		if amt >= 10000 then
			self:AwardAchievement("zomhun");
		end
		if amt >= 100000 then
			self:AwardAchievement("zomext");
		end
		if amt >= 1000000 then
			self:AwardAchievement("zomann");
		end
		
		self.Profile.DailyStats.ZombieKills = (self.Profile.DailyStats.ZombieKills or 0) + amount;
		self.Profile.WeeklyStats.ZombieKills = (self.Profile.WeeklyStats.ZombieKills or 0) + amount;
		
	end
	
	self:Sync("Stats/"..key);
end

function SaveData:FindItemFromStorages(id)
	if self.Inventory.Container[id] then
		return self.Inventory.Container[id], self.Inventory;
	end
	if self.Clothing.Container[id] then
		return self.Clothing.Container[id], self.Clothing;
	end
	for name, storage in pairs(self.Storages) do
		if storage.Container[id] then
			return storage.Container[id], storage;
		end;
	end
	return;
end

function SaveData:CalculateLevel()
	local previousLevel = self:GetStat("Level") or 0;
	local totalLevels = self:SumMasteries();
	self:SetStat("Level", math.clamp(totalLevels, 0, modGlobalVars.MaxLevels)); 
	if totalLevels > previousLevel then
		if totalLevels ~= 0 and math.fmod(totalLevels, 5) == 0 then
			self:AddStat("Perks", 10);
			shared.Notify(self.Player, (("+10 Perks for reaching level $level."):gsub("$level", totalLevels)), "Reward");
		end
		remoteHudNotification:FireClient(self.Player, "Levelup", {Level=totalLevels;});
		
		self:Sync("Masteries");
		remoteMasterySync:FireAllClients(self.Player.Name, self.Level);
		
		local unlockedNewSkill = false;
		if not unlockedNewSkill then
			for a=1, #libAuthTree do
				if libAuthTree[a].Level == totalLevels then
					unlockedNewSkill = true;
				end
			end
		end
		if not unlockedNewSkill then
			for a=1, #libEnduTree do
				if libEnduTree[a].Level == totalLevels then
					unlockedNewSkill = true;
				end
			end
		end
		if not unlockedNewSkill then
			for a=1, #libSyneTree do
				if libSyneTree[a].Level == totalLevels then
					unlockedNewSkill = true;
				end
			end
		end
		if unlockedNewSkill then
			shared.Notify(self.Player, "New skill unlocked, press [L] to open your masteries menu.", "Inform");
		end
		
		if totalLevels < 10 then
			modAnalytics.RecordProgression(self.Player.UserId, "Complete", "MasteryLevel:"..totalLevels);
		elseif totalLevels < 500 and math.fmod(totalLevels, 10) == 0 then
			modAnalytics.RecordProgression(self.Player.UserId, "Complete", "MasteryLevel:"..totalLevels);
		elseif totalLevels < 1000 and math.fmod(totalLevels, 50) == 0 then
			modAnalytics.RecordProgression(self.Player.UserId, "Complete", "MasteryLevel:"..totalLevels);
		elseif math.fmod(totalLevels, 100) == 0 then
			modAnalytics.RecordProgression(self.Player.UserId, "Complete", "MasteryLevel:"..totalLevels);
		end
	end
	pcall(function()
		local iconLevelTag = self.Player and self.Player.Character and self.Player.Character:FindFirstChild("LevelIcon", true);
		if self.Player and self.Player.Character and self.Player.Character:FindFirstChild("LevelIcon", true) then
			iconLevelTag.LevelTag.Text = totalLevels;
		end
	end)
end

function SaveData:AwardAchievement(id, giveBadge)
	local lib = modAchievementLibrary:Find(id);
	if lib then
		if self.Achievements[id] == nil then
			shared.Notify(lib.PublicAnnounce and game.Players or self.Player, 
				(lib.Announce.."$Perks")
				:gsub("$PlayerName", "["..self.Player.Name.."]: ")
				:gsub("$Perks", lib.Tier.Perks and " (+"..lib.Tier.Perks.." Perks)" or ""), "Reward");
			
			if lib.PublicAnnounce and self.Player and self.Player.Character and self.Player.Character.PrimaryPart then
				modAudio.Play("Ascended", self.Player.Character.PrimaryPart);
			end
			
			local largestNum = 0;
			for key, num in pairs(self.Achievements) do
				if num > largestNum then
					largestNum = num;
				end
			end
			self.Achievements[id] = largestNum+1;
			if lib.Tier.Perks then self:AddStat("Perks", lib.Tier.Perks); end;
			
			if giveBadge ~= false then
				spawn(function()
					if not BadgeService:UserHasBadgeAsync(self.Player.UserId, lib.BadgeId) then
						BadgeService:AwardBadge(self.Player.UserId, lib.BadgeId);
					end
				end)
			end
		end
	end
end

function SaveData:SumMasteries()
	local total = 0;
	for k, v in pairs(self.Masteries) do
		total = total+v;
		
		if v >= 20 then
			self:AwardAchievement("maawe");
		end
	end
	return total;
end

function SaveData:GetMasteries(key)
	return self.Masteries[key];
end

function SaveData:SetMasteries(key, amount)
	self.Masteries[key] = amount and math.clamp(amount, 0, 20) or nil;
	if key == "Admin" or key == "Dummy" then self.Masteries[key] = amount; end
	self:CalculateLevel();
end

function SaveData:ResetInventory()
	self.Inventory = modStorage.new("Inventory", "Inventory", 30, self.Player);
	self.Inventory:Sync();
end

function SaveData:NewMail(mailObject)
	table.insert(self.Mailbox, mailObject);
end

function SaveData:SyncMail()
	self:Sync("Mailbox")
end

return SaveData;