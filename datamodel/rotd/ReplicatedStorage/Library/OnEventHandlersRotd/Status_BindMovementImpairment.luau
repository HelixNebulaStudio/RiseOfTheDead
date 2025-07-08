local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

return function(event: EventPacket, player: Player, statusTable)
	local playerClass: PlayerClass = shared.modPlayers.get(player);
    if playerClass == nil then return end;

    local cMoveImpairReduction = playerClass.Configurations.MoveImpairReduction;

    if cMoveImpairReduction then
        local deduct = statusTable.Duration * cMoveImpairReduction;
        statusTable.Duration = math.max(statusTable.Duration-deduct, 0);
    end
end;
