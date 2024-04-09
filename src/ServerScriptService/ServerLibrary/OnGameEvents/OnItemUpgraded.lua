local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);


--== When OnItemUpgraded;
return function(player, item)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local inventory = activeSave.Inventory;
	local modLib = modModsLibrary.Get(item.ItemId);
	
	if item.ItemId == "pistoldamagemod" then
		if modMission:Progress(player, 5) then
			modMission:CompleteMission(player, 5);
		end
	end
	
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
