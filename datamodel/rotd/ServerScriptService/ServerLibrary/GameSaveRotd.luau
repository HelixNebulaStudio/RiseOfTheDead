local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGameSave = shared.require(game.ServerScriptService.ServerLibrary.GameSave);

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);

local modSkillTreeLibrary = shared.require(game.ReplicatedStorage.Library.SkillTreeLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modStoragePresetsLibrary = shared.require(game.ReplicatedStorage.Library.StoragePresetsLibrary);
local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);

local modBlueprints = shared.require(game.ServerScriptService.ServerLibrary.Blueprints);
local modAnalytics = shared.require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);
local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);

local remoteMasterySync;
local remoteHudNotification;

local libAuthTree, libEnduTree, libSyneTree;
--==
function modGameSave.onRequire()
	remoteMasterySync = modRemotesManager:Get("MasterySync");
	remoteHudNotification = modRemotesManager:Get("HudNotification");
end

shared.coreBind(modGameSave, "_new", function(gameSave: GameSaveRotd, profile: ProfileRotd)
	local player = profile.Player;
	Debugger:Warn("_new GameSave", player);

	gameSave.Masteries = {};
	gameSave.Blueprints = modBlueprints.new(player, function() gameSave:Sync("Blueprints") end);

	local wardrobeStorage: Storage = modStorage.new("Wardrobe", "Wardrobe", player);
	wardrobeStorage:ConnectCheck(function(packet)
		local dragStorageItem = packet.DragStorageItem;
		local targetStorageItem = packet.TargetStorageItem;
		
		if packet.DragStorage == gameSave.Wardrobe then packet.Allowed = true; return packet; end;
		if targetStorageItem and dragStorageItem.ItemId == targetStorageItem.ItemId then packet.Allowed = true; return packet; end;
		if dragStorageItem then
			if dragStorageItem.Library.Type == modItemsLibrary.Types.Clothing then
				packet.Allowed = true;
				return packet;
			end
			packet.FailMsg = "Item "..dragStorageItem.ItemId.." is not allowed in wardrobe storage.";
		end
		
		packet.Allowed = false;
		return packet;
	end);
	gameSave.Storages.Wardrobe = wardrobeStorage;
	--Adding new storages requires adding sync in inv interface;

end)

shared.coreBind(modGameSave, "_load_storage", function(gameSave: GameSaveRotd, storageId: string, rawStorage)
	local player = gameSave.Player;
	--Debugger:Warn("_load_storage GameSave", player, storageId);
	
	if storageId == "Safehouse Storage" then
		storageId = "Safehouse";
	end
	if storageId == "Inventory" then
		rawStorage.Name = "Inventory";
	elseif storageId == "Safehouse" then
		rawStorage.Name = "Safehouse Storage";
	end
	
	local storagePresetLib = modStoragePresetsLibrary:Find(storageId);
	local presetId = rawStorage.PresetId;

	if storagePresetLib then
		presetId = storagePresetLib.Id;
	end

	if presetId == nil then
		-- loaded before v2.3;

		local npcNameTest = storageId:gsub("Storage", "");
		local storageSuffix = storageId:sub(#storageId-6,#storageId);
		
		if storageId:sub(1,1) == "#" and tonumber(storageId:sub(2, #storageId)) ~= nil then
			presetId = "attachmentmods";

		elseif storageId:sub(1,9) == "Safehouse" then
			presetId = "Safehouse";

		elseif storageId:sub(1,10) == "RatStorage" then
			presetId = "RatStorage";

		elseif storageSuffix == "Storage" and modNpcProfileLibrary:Find(npcNameTest) then
			presetId = "npcstorage";

		elseif storageId:sub(#storageId-3, #storageId) == "Gift" then
			presetId = "giftcrate";

		end

		if presetId then
			storagePresetLib = modStoragePresetsLibrary:Find(presetId);
		end
	end

	if storagePresetLib == nil then
		Debugger:Warn(`Storage ({storageId}) type does not exist ({presetId})`);
		return;
	end

	if gameSave.Storages[storageId] then
		Debugger:Warn(`Storage ({storageId}) already instantiated`);
		return gameSave.Storages[storageId];
	end

	local storage: Storage = gameSave.Storages[storageId];
	if storage == nil then
		storage = modStorage.new(storageId, presetId, player, rawStorage.Name);
	end
	
	return storage;
end)

function modGameSave:SumMasteries()
	local total = 0;
	for k, v in pairs(self.Masteries) do
		total = total+v;
		
		if v >= 20 then
			self:AwardAchievement("maawe");
		end
	end
	return total;
end

function modGameSave:GetMasteries(key)
	return self.Masteries[key];
end

function modGameSave:SetMasteries(key, amount)
	self.Masteries[key] = amount and math.clamp(amount, 0, 20) or nil;
	if key == "Admin" or key == "Dummy" then self.Masteries[key] = amount; end
	self:CalculateLevel();
end

function modGameSave:CalculateLevel()
	local previousLevel = self:GetStat("Level") or 0;
	local totalLevels = self:SumMasteries();
	self:SetStat("Level", math.clamp(totalLevels, 0, modGlobalVars.MaxLevels));

	if totalLevels > previousLevel then
		if totalLevels ~= 0 and math.fmod(totalLevels, 5) == 0 then
			self:AddStat("Perks", 10);
			shared.Notify(self.Player, (("+10 Perks for reaching level $level."):gsub("$level", totalLevels)), "Reward");

			modAnalyticsService:Source{
				Player=self.Player;
				Currency=modAnalyticsService.Currency.Perks;
				Amount=10;
				EndBalance=self:GetStat("Perks");
				ItemSKU=`LevelMilestone`;
			};
		end
		remoteHudNotification:FireClient(self.Player, "Levelup", {Level=totalLevels;});
		
		self:Sync("Masteries");
		remoteMasterySync:FireAllClients(self.Player.Name, self.Level);
		
		local unlockedNewSkill = false;
		if not unlockedNewSkill then
			if libAuthTree == nil then
				libAuthTree = modSkillTreeLibrary.Authority:GetSorted();
			end
			for a=1, #libAuthTree do
				if libAuthTree[a].Level == totalLevels then
					unlockedNewSkill = true;
				end
			end
		end
		if not unlockedNewSkill then
			if libEnduTree == nil then
				libEnduTree = modSkillTreeLibrary.Endurance:GetSorted();
			end
			for a=1, #libEnduTree do
				if libEnduTree[a].Level == totalLevels then
					unlockedNewSkill = true;
				end
			end
		end
		if not unlockedNewSkill then
			if libSyneTree == nil then
				libSyneTree = modSkillTreeLibrary.Synergy:GetSorted();
			end
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

return modGameSave;