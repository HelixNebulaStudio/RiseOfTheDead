local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modWeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);

function Mod.Activate(packet)
	local module = packet.WeaponModule;
	
	local layerInfo = modModsLibrary.GetLayer("F", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + math.ceil(tweakVal);
	end

	if module.Configurations.Flameburst == nil then
		module.Configurations.Flameburst = true;

		module.Properties.Multishot = 3;
		module.Configurations.ModInaccuracy = 16;
		module.Configurations.ProjectileId = "gasFlame";
		module.Configurations.KnockbackForce = value or 5;
	end
end

return Mod;