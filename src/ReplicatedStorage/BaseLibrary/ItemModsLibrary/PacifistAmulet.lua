local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;
	local modStorageItem = packet.ModStorageItem;
	
	local info = itemMod.Library.Get(packet.ItemId);
	if module:RegisterTypes(info, modStorageItem) then
		return;
	end;
	
	local apLayerInfo = itemMod.Library.GetLayer("AP", packet);
	local apValue, apTweakVal = apLayerInfo.Value, apLayerInfo.TweakValue;
	
	if apTweakVal then
		apValue = apValue + apTweakVal;
	end

	local arLayerInfo = itemMod.Library.GetLayer("AR", packet);
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

return itemMod;