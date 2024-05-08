local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);

return function(player: Player, interactData) -- IsServer();
	if interactData.Type == modInteractables.Types.Pickup then
		local profile = shared.modProfile:Get(player);
		
		if profile.Cache.OnResourceGathererCooldown and tick()-profile.Cache.OnResourceGathererCooldown <= 1 then return end;
		profile.Cache.OnResourceGathererCooldown = tick();

		local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
		modOnGameEvents:Fire("OnResourceGatherers", player, interactData);
	end
end;