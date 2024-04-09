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
	});
	
	--local storageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = modModsLibrary.Get(storageItem.ItemId);
	--if module:RegisterTypes(info, storageItem) then return end;
	--local values = storageItem.Values;

	--local hpk = modModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["HPK"], info.Upgrades[1].MaxLevel, info.Upgrades[1].Rate);
	--local hp = modModsLibrary.Linear(info.Upgrades[2].BaseValue, info.Upgrades[2].MaxValue, values["HP"], info.Upgrades[2].MaxLevel, info.Upgrades[2].Rate);
	
	--module:RegisterPlayerProperty("WarmongerScales", {
	--	HealthPerKill=hpk;
	--	Max=hp;
	--});
end

return Mod;