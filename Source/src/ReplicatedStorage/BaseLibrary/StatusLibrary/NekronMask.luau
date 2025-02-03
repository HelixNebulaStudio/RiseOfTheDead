local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="NekronMask";
    Icon="rbxassetid://5419783427";
    Name="Nekron Mask";
    Description="When this effect is over, the Nekron Mask is consumed.";
    Buff=true;
};

function statusPackage:OnExpire()
	if RunService:IsClient() then return end;
	local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

	local player = playerClass:GetInstance();
	local storageItemId = self.StorageItemId;
	
	local _, storage = shared.modStorage.FindIdFromStorages(storageItemId, player);
	if storage == nil then return end;

	storage:Remove(storageItemId);
	shared.Notify(player, "Your Nekron Mask has been consumed.", "Negative");
end

return modStatusClass.new(statusPackage);