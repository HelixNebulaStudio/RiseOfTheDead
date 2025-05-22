local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

local modifierPackage = {
	Name = "Damage Calibre";

	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "DS");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.SetValues.RpmScaler = value;
	modifier.SetValues.DamageScaler = -value; 
end

function modifierPackage.Instancing(modifier: ItemModifierInstance, isFirstTime: boolean)
	if not isFirstTime then return end;
	if RunService:IsClient() then return end;

	local remoteItemModAction = modRemotesManager:Get("ItemModAction");
	function remoteItemModAction.OnServerInvoke(player, action, ...)
		Debugger:Warn("remoteItemModAction", player, action, ...);
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

if true then return modifierPackage; end













local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModProperties = shared.require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local remoteItemModAction = modRemotesManager:Get("ItemModAction");

function itemMod.Activate(packet)
	local module = packet.WeaponModule;
	
	local modStorageItem = packet.ModStorageItem;
	local itemValues = modStorageItem.Values;
	
	local layerInfo = itemMod.Library.GetLayer("DS", packet);
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

return itemMod;