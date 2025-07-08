local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="Ragdolling";
    Description="Character is ragdolling";
    ShowOnHud=false;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    playerClass.Humanoid.PlatformStand = true;
    playerClass.Properties.Ragdoll = 1;

    if RunService:IsClient() then
		local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
		local modCharacter = modData:GetModCharacter();

		modCharacter.CharacterProperties.Ragdoll = true;
		if statusClass.Values.CanAction ~= true then
			modCharacter.CharacterProperties.CanAction = false;
		end
    end
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    playerClass.Humanoid.PlatformStand = false;
    playerClass.Properties.Ragdoll = 0;

    if RunService:IsClient() then
		local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
		local modCharacter = modData:GetModCharacter();

        modCharacter.CharacterProperties.Ragdoll = false;
        modCharacter.CharacterProperties.CanAction = true;
    end

end

return modStatusClass.new(statusPackage);