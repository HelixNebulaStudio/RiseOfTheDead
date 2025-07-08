local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

return function(event: EventPacket, interactData, storageItem) -- IsServer();
	local player: Player? = event.Player;
	if player == nil then return end;
	 
	if interactData.Type == modInteractables.Types.Pickup then
		local profile = shared.modProfile:Get(player);
		
		if profile.Cache.OnResourceGathererCooldown and tick()-profile.Cache.OnResourceGathererCooldown <= 1 then return end;
		profile.Cache.OnResourceGathererCooldown = tick();

		shared.modEventService:ServerInvoke("Skills_BindResourceGatherers", {ReplicateTo={player}}, player, interactData);
	end
end;