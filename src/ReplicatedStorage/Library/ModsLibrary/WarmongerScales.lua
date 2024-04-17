local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local hpkLayerInfo = modModsLibrary.GetLayer("HPK", packet);
	local hpkValue, hpkTweakVal = hpkLayerInfo.Value, hpkLayerInfo.TweakValue;

	if hpkTweakVal then
		hpkValue = hpkValue + hpkTweakVal;
	end

	local hpLayerInfo = modModsLibrary.GetLayer("HP", packet);
	local hpValue, hpTweakVal = hpLayerInfo.Value, hpLayerInfo.TweakValue;

	if hpTweakVal then
		hpValue = hpValue + hpTweakVal;
	end
	
	module:RegisterPlayerProperty("WarmongerScales", {
		HealthPerKill=hpkValue;
		Max=hpValue;
	}, true);
end

return Mod;