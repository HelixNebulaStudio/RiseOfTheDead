local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modRichFormatter = shared.require(game.ReplicatedStorage.Library.UI.RichFormatter);

return function(eventPacket: EventPacket, ...)
	if RunService:IsClient() then return end;
    local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	local players = eventPacket.Players;
	local newPrefab, interactable: InteractableInstance = ...;

	task.spawn(function()
		local storageId = interactable.Values.StorageId;
		if storageId == nil then
			Debugger:Warn("Missing storageId.");
			return;
		end
	
		for a=1, #players do
			local player = players[a];

			local crateStorage: Storage? = shared.modStorage.Get(storageId, player);
			if crateStorage == nil then continue end;

			local mission = modMission:GetMission(player, 77);
			if mission then
				if mission.Type == 2 then
					if storageId:sub(1,11) == "sunkenchest" then
						crateStorage:Add("blueprintpiece", {
							CustomName = shared.modStorage.RegisterItemName("Turret Blueprint Piece");
							Values = {
								DescExtend = modRichFormatter.H3Text("\nMission: ").."Ask the Mysterious Engineer about this.";
							};
						});
					end
					
				elseif mission.Type == 1 then
					if mission.ProgressionPoint == 5 then
					end
				end
			end;

		end

	end)	
end;