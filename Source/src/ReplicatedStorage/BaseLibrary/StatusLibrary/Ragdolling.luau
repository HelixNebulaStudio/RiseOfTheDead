local RunService = game:GetService("RunService");
local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="Ragdolling";
    Description="Character is ragdolling";
    ShowOnHud=false;
};

function statusPackage:OnApply()
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    playerClass.Humanoid.PlatformStand = true;
    playerClass:SetProperties("Ragdoll", 1);
    
    if RunService:IsClient() then
		local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
		local modCharacter = modData:GetModCharacter();

		modCharacter.CharacterProperties.Ragdoll = true;
		if self.CanAction ~= true then
			modCharacter.CharacterProperties.CanAction = false;
		end
    end
end

function statusPackage:OnExpire()
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    playerClass.Humanoid.PlatformStand = false;
    playerClass:SetProperties("Ragdoll", 0);
    
    if RunService:IsClient() then
		local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
		local modCharacter = modData:GetModCharacter();

        modCharacter.CharacterProperties.Ragdoll = false;
        modCharacter.CharacterProperties.CanAction = true;
    end

end

return modStatusClass.new(statusPackage);