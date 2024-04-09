local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local DataStoreService = game:GetService("DataStoreService");
local HttpService = game:GetService("HttpService");

local LegacyData = {};
--== Script;
function LegacyData.HasLegacyData(userId)
	local legacySaveSlots = {};
	local loadSuccess, loadError = pcall(function()
		for a=1, 3 do
			local saveDataStore = DataStoreService:GetDataStore("SaveGame_"..a, "ID_"..userId);
			local rawSaveData = saveDataStore:GetAsync("SaveData");
			if rawSaveData ~= nil then table.insert(legacySaveSlots, a) end;
		end
	end)
	return #legacySaveSlots > 0 and legacySaveSlots or nil;
end

function LegacyData.Load(userId, index)
	index = index or 1;
	local legacySave = {};
	local loadSuccess, loadError = pcall(function()
		local saveDataStore = DataStoreService:GetDataStore("SaveGame_"..index, "ID_"..userId);
		local rawSaveData = saveDataStore:GetAsync("SaveData");
		local saveData = rawSaveData and HttpService:JSONDecode(rawSaveData) or nil;
		if saveData then
			--== Blueprints;
			local ownnedItems = {};
			if saveData.Inventory then
				for a=1, #saveData.Inventory do
					local itemName = saveData.Inventory[a].Name;
					if itemName:find("Blueprint") then
						if legacySave.Blueprints == nil then legacySave.Blueprints = {} end;
						table.insert(legacySave.Blueprints, itemName);
					end
					table.insert(ownnedItems, itemName);
				end
			end
			--== Weapons;
			if saveData.Stats and saveData.Stats.Weapons then
				for weaponName, _ in pairs(saveData.Stats.Weapons) do
					if weaponName ~= "P250"
					and weaponName ~= "Ultra P250"
					and weaponName ~= "Ultra Sawed-Off"
					and weaponName ~= "Ultra M4A4"
					and weaponName ~= "Ultra Tec-9" then
						if legacySave.Weapons == nil then legacySave.Weapons = {}; end;
						table.insert(legacySave.Weapons, weaponName);
					end
				end
			end
		else
			legacySave = nil;
		end
	end)
	if not loadSuccess then
		Debugger:Log("("..userId..") Load failed: ", loadError);
	end
	return legacySave;
end

return LegacyData;