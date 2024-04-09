local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);


--== When something happens;
return function(destructible, player, storageItem)
	if player == nil then return end
	local profile = modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	local inventory = activeSave and activeSave.Inventory;
	
end;
