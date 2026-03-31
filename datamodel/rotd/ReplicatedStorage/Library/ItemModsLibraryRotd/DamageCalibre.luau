local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Damage Calibre";

	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	modItemModifierClass.AddTierDamage(modifier);
	
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "DS");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.ProductValues.Damage = 1+value;
	modifier.ProductValues.Rpm = 1-value;
end

if RunService:IsServer() then
	function modifierPackage.Binds.ModifierSetValue(modifier: ItemModifierInstance, packet)
		if packet.Key ~= script.Name then return end;
		if packet.DataTag ~= "DSS" then return end;

		local storageItem = modifier.ItemModStorageItem;
		local value = packet.Value;

		if storageItem == nil or storageItem.Values.DS == nil then return end;
		
		local newVal = math.clamp(value or 0, 0, storageItem.Values.DS);
		storageItem:SetValues(packet.DataTag, newVal);
	end
end

return modifierPackage;