local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;
	local modStorageItem = packet.ModStorageItem;
	
	local info = modModsLibrary.Get(packet.ItemId);
	if module:RegisterTypes(info, modStorageItem) then return end;
	
	local apLayerInfo = modModsLibrary.GetLayer("AP", packet);
	local apValue, apTweakVal = apLayerInfo.Value, apLayerInfo.TweakValue;
	
	if apTweakVal then
		apValue = apValue + apTweakVal;
	end

	local arLayerInfo = modModsLibrary.GetLayer("AR", packet);
	local arValue, arTweakVal = arLayerInfo.Value, arLayerInfo.TweakValue;

	if arTweakVal then
		arValue = arValue + arTweakVal;
	end
	
	module:RegisterPlayerProperty("PacifistsAmulet", {
		AddAp = apValue;
		AddAr = arValue;
		Visible = false;
	});
	
	--local storageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = modModsLibrary.Get(storageItem.ItemId);
	--if module:RegisterTypes(info, storageItem) then return end;
	
	--local values = storageItem.Values;

	--local addArmorPoints = modModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["AP"], info.Upgrades[1].MaxLevel, info.Upgrades[1].Rate);
	--local addArmorRate = modModsLibrary.Linear(info.Upgrades[2].BaseValue, info.Upgrades[2].MaxValue, values["AR"], info.Upgrades[2].MaxLevel, info.Upgrades[2].Rate);
	
	--module:RegisterPlayerProperty("PacifistsAmulet", {
	--	AddAp = addArmorPoints;
	--	AddAr = addArmorRate;
	--	Visible = false;
	--});
end

return Mod;
