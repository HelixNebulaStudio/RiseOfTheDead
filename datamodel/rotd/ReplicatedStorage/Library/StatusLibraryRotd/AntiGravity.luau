local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="AntiGravity";
    Description="Applies opposite gravitational forces of $Amount u/s to the character.";
    ShowOnHud=false;
};


function statusPackage.OnApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local playerClass = statusClass.StatusOwner :: PlayerClass;
	if playerClass == nil then return end;

    local bodyForce = statusClass.Values.BodyForce;
    if bodyForce == nil then
        bodyForce = Instance.new("BodyForce");
        bodyForce.Name = "AntiGravity";
        statusClass.Garbage:Tag(bodyForce);
        statusClass.Values.BodyForce = bodyForce;
    end

    playerClass.Humanoid.PlatformStand = true;

    bodyForce:SetAttribute("Gravity", statusClass.Values.Amount or 1000);
    bodyForce.Parent = playerClass.RootPart;

end

function statusPackage.OnExpire(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local playerClass = statusClass.StatusOwner :: PlayerClass;
	if playerClass == nil then return end;

    playerClass.Humanoid.PlatformStand = false;

end

return modStatusClass.new(statusPackage);