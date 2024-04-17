local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;
	local modStorageItem = packet.ModStorageItem;
	
	local info = modModsLibrary.Get(packet.ItemId);
	if module:RegisterTypes(info, modStorageItem) then
		return;
	end;
	
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
	}, true);
end

return Mod;