local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modRichFormatter = shared.require(game.ReplicatedStorage.Library.UI.RichFormatter);

return function(eventPacket: EventPacket, ...)
	if RunService:IsClient() then return end;
    local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	local players = eventPacket.Players;
	local newPrefab, interactable: InteractableInstance = ...;
	
end;