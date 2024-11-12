local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);


local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modItemModsLibrary = modModEngineService:GetBaseModule("ItemModsLibrary");

--== When OnItemUpgraded;
return function(player, item)
	if modItemModsLibrary == nil then return end;

	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local inventory = activeSave.Inventory;
	local modLib = modItemModsLibrary.Get(item.ItemId);
	
	if modLib.Module.Name == "Damage"  then
		local maxLevel = 10;
		for a=1, #modLib.Upgrades do
			if modLib.Upgrades[a].DataTag == "D" then
				maxLevel = modLib.Upgrades[a].MaxLevel;
				break;
			end
		end
		if item.Values and item.Values.D == maxLevel then
			activeSave:AwardAchievement("dammas");
		end
	end
end;
