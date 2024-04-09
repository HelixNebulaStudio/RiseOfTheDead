local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

return function(player, interactData)
	local profile = shared.modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	local inventory = activeSave and activeSave.Inventory;
	
	if interactData.Type == modInteractables.Types.Pickup then
		local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
		modOnGameEvents:Fire("OnResourceGatherers", player, interactData);
	end
end;
