local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="NekronMask";
    Icon="rbxassetid://5419783427";
    Name="Nekron Mask";
    Description="When this effect is over, the Nekron Mask is consumed.";
    Buff=true;
};

function statusPackage.BindExpire(statusClass: StatusClassInstance)
	if RunService:IsClient() then return end;
	local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil or playerClass.ClassName ~= "PlayerClass" then return end;

	local player: Player = playerClass:GetInstance();
	local storageItemId = statusClass.Values.StorageItemId;

	local _, storage = shared.modStorage.FindIdFromStorages(storageItemId, player);
	if storage == nil then return end;

	storage:Remove(storageItemId);
	shared.Notify(player, "Your Nekron Mask has been consumed.", "Negative");
end

return modStatusClass.new(statusPackage);