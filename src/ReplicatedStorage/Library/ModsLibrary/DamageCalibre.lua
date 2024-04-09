local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local remoteItemModAction = modRemotesManager:Get("ItemModAction");

function Mod.Activate(packet)
	local module = packet.WeaponModule;
	
	local modStorageItem = packet.ModStorageItem;
	local itemValues = modStorageItem.Values;
	
	local layerInfo = modModsLibrary.GetLayer("DS", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	local activeMulti = module.Configurations.DamageCalibre;
	if activeMulti == 0 then return end;
	
	if module.Configurations.DamageCalibre then return end;
	module.Configurations.DamageCalibre = value;

	local fireRate = 60/module.Properties.Rpm;
	local dps = module.Configurations.Damage/fireRate;

	module.Properties.Rpm = module.Properties.Rpm * (1-value);

	local newDmg = dps * (60/module.Properties.Rpm);
	module.Configurations.Damage = newDmg;
	
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local level = math.clamp((values["DS"] or 0), 0, info.Upgrades[1].MaxLevel-paramPacket.TierOffset);
	--local sliderVal = math.clamp(values["DSS"] or level, 0, level);
	
	--local multi = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, sliderVal, info.Upgrades[1].MaxLevel, info.Upgrades[1].Rate);
	
	--local activeMulti = module.Configurations.DamageCalibre;
	--if activeMulti == 0 then return end;
	
	--if module.Configurations.DamageCalibre then return end;
	--module.Configurations.DamageCalibre = multi;
	
	--local fireRate = 60/module.Properties.Rpm;
	--local dps = module.Configurations.Damage/fireRate;

	--module.Properties.Rpm = module.Properties.Rpm * (1-multi);

	--local newDmg = dps * (60/module.Properties.Rpm);
	--module.Configurations.Damage = newDmg;
	
end

if RunService:IsServer() then
	function remoteItemModAction.OnServerInvoke(player, action, ...)
		if action ~= "setvalue" then return end;
		local packet = ...;
		if packet.Key ~= script.Name then return end;
		
		local profile = shared.modProfile:Get(player);
		local activeSave = profile:GetActiveSave();

		local storageItemOfMod, storageOfMod = activeSave:FindItemFromStorages(packet.StorageItemID);
		if storageItemOfMod == nil then return end;
		if packet.DataTag ~= "DSS" then return end;
		if storageItemOfMod.Values.DS == nil then return end;
		
		local newVal = math.clamp(packet.Value or 0, 0, storageItemOfMod.Values.DS);
		
		storageOfMod:SetValues(packet.StorageItemID, {
			[packet.DataTag]=newVal;
		});
	end
	
end

return Mod;