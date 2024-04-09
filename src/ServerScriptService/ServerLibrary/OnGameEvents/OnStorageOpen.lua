local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);


--== When something happens;
return function(player, interactData)
	if interactData.ItemId then return; end -- Storage Event for virtual storages.
	if interactData.Type ~= modInteractables.Types.Storage then return end;
	
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local inventory = activeSave and activeSave.Inventory;
	
	local storageId = interactData.StorageId;
	
	if storageId == "thebackupplan" then
		if modMission:Progress(player, 22) then
			modMission:Progress(player, 22, function(mission)
				if mission.ProgressionPoint == 3 then
					mission.ProgressionPoint = 4;
				end;
			end)
		end
		
	end
end;
