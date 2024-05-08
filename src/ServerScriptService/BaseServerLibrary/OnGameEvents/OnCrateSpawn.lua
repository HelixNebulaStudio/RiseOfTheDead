local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);

--== When something happens;
return function(cratePrefab, interactData, cratePlayers)
	local storageId = interactData.StorageId;
	if cratePlayers == nil then return end;
	
	for a=1, #cratePlayers do
		local player = cratePlayers[a];
		
		--local profile = shared.modProfile:Get(player);
		--local playerSave = profile:GetActiveSave();
		
		local crateStorage = shared.modStorage.Get(storageId, player);
		if crateStorage == nil then continue end;

		local mission = shared.modMission:GetMission(player, 77);
		if mission then
			if mission.Type == 2 then
				if interactData.RefStorageId == "sunkenchest" then
					crateStorage:Add("blueprintpiece", {Values={
						Name=shared.modStorage.RegisterItemName("Turret Blueprint Piece");
						DescExtend=modRichFormatter.H3Text("\nMission: ").."Ask the Mysterious Engineer about this.";
					};});
				end
				
			elseif mission.Type == 1 then
				if mission.ProgressionPoint == 5 then
				end
			end
		end;
	end
	
end;