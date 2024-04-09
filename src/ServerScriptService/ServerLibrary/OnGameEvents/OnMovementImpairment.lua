local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modPlayers = require(game.ReplicatedStorage.Library.Players);


--== When something happens;
return function(player, statusTable)
	--local profile = modProfile:Get(player);
	--local activeSave = profile:GetActiveSave();
	--local inventory = activeSave.Inventory;

	local classPlayer = modPlayers.Get(player);
	if classPlayer then
		local moveImpairReduct = classPlayer:GetBodyEquipment("MoveImpairReduction");
		
		if moveImpairReduct then
			local deduct = statusTable.Duration * moveImpairReduct;
			statusTable.Duration = math.max(statusTable.Duration-deduct, 0);
			
		end
	end
end;
