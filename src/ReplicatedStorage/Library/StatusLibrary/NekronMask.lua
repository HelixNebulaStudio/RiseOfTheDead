local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local StatusClass = require(script.Parent.StatusClass).new();

local RunService = game:GetService("RunService");

if RunService:IsServer() then
	modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
end

--==

function StatusClass.OnExpire(classPlayer, status)
	if not RunService:IsServer() then Debugger:Log("Clientside expire"); return end;
	
	local player = classPlayer:GetInstance();
	local storageItemId = status.StorageItemId;
	
	local _, storage = modStorage.FindIdFromStorages(storageItemId, player);
	if storage == nil then Debugger:Log("Unknown storage to remove nekron mask."); return end;

	storage:Remove(storageItemId);
	shared.Notify(player, "Your Nekron Mask has been consumed.", "Negative");
end

return StatusClass;
