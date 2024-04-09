local Cosmetics = {}

local MarketplaceService = game:GetService("MarketplaceService");
local modAppearanceLibrary = require(game.ReplicatedStorage.Library.AppearanceLibrary);
local modCustomizeAppearance = require(game.ReplicatedStorage.Library.CustomizeAppearance);

local cosmeticsPrefabs = game.ServerStorage:WaitForChild("PrefabStorage"):WaitForChild("Cosmetics");

function Cosmetics.new(player)
	local cosmeticsMeta = {};
	cosmeticsMeta.__index = cosmeticsMeta;
	cosmeticsMeta.Player = player;
	local cosmetics = setmetatable({}, cosmeticsMeta);
	cosmetics.Equipped = {};
	
	cosmetics.Accessory = {};
	cosmetics.HairGroup = {};
	cosmetics.HeadGroup = {};
	cosmetics.ChestGroup = {};
	cosmetics.ArmGroup = {};
	cosmetics.HandGroup = {};
	cosmetics.WaistGroup = {};
	cosmetics.LegGroup = {};
	cosmetics.FootGroup = {};
	
	cosmeticsMeta.IsEquipped = function(group, name)
		if cosmetics.Equipped[group] and cosmetics.Equipped[group] == name then
			return true;
		end
		return false;
	end
	
	cosmeticsMeta.SetEquip = function(group, name)
		local oriVal = cosmetics.Equipped[group];
		cosmetics.Equipped[group] = name;
		
		if player.Character == nil then return end;
		if oriVal ~= name then
			if name == nil then
				modCustomizeAppearance.RemoveAccessory(player.Character, group);
			else
				local accessoryData, accessoryGroup = modAppearanceLibrary:Get(group, name);
				if accessoryData == nil then warn(script.Name..">>  Accessory "..name.." ("..group..") does not exist."); end
				local accessories = modCustomizeAppearance.LoadAccessory(accessoryData);
				
				for a=1, #accessories do
					modCustomizeAppearance.AttachAccessory(player.Character, accessories[a], accessoryData, group);
				end
			end
		end
	end
	cosmeticsMeta.AddAccessory = function(group, name)
		if cosmetics[group] == nil then cosmetics[group] = {} end;
		cosmetics[group][name] = 1;
	end
	cosmeticsMeta.RemoveAccessory = function(group, name)
		if cosmetics[group] then
			cosmetics[group][name] = nil;
		end;
	end
	cosmeticsMeta.HasAccessory = function(player, group, name)
		local assetData = modAppearanceLibrary:Get(group, name);
		if cosmetics[group] then
			if cosmetics[group][name] then
				return true;
			end
		end
		if assetData and assetData.Store == modAppearanceLibrary.EnumStore.Marketplace then
--			if MarketplaceService:PlayerOwnsAsset(player, assetData.AssetId) then
--				cosmeticsMeta.AddAccessory(group, name);
--				return true;
--			end
		end
		return false;
	end
	
	cosmeticsMeta.ToggleAccessory = function(acctype)
		if cosmetics.Accessory[acctype] == nil then
			cosmetics.Accessory[acctype] = false;
		elseif cosmetics.Accessory[acctype] == false then
			cosmetics.Accessory[acctype] = nil;
		end
		return cosmetics.Accessory[acctype];
	end
	
	cosmeticsMeta.__newindex = function(self, key, value) if rawget(cosmetics, key) == nil then cosmeticsMeta[key] = value; end; end;
	return cosmetics;
end

function Cosmetics.load(rawTable)
	local cosmetics = Cosmetics.new();
	
	for key, value in pairs(rawTable) do
		if cosmetics[key] then
			cosmetics[key] = value;
		end
	end
	
	return cosmetics;
end

return Cosmetics;