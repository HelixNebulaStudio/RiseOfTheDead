local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("A", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	module.NekrosisAmpMulti = value;

	if module.BaseNekrosisHeal == nil then return end

	local new = module.BaseNekrosisHeal + (module.BaseNekrosisHeal * value);
	if new < module.ModNekrosisHeal then return end;

	module.ModNekrosisHeal = new;
end

return itemMod;