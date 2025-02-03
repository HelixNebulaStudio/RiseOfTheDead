local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="AntiGravity";
    Description="Applies opposite gravitational forces of $Amount u/s to the character.";
    ShowOnHud=false;
};


function statusPackage:OnApply()
    if RunService:IsClient() then return end;
    local playerClass = self.PlayerClass;
	if playerClass == nil then return end;

    
    if self.BodyForce == nil then
        self.BodyForce = Instance.new("BodyForce");
        self.BodyForce.Name = "AntiGravity";
        self.Garbage:Tag(self.BodyForce);
    end

    playerClass.Humanoid.PlatformStand = true;
    
    self.BodyForce:SetAttribute("Gravity", self.Amount or 1000);
    self.BodyForce.Parent = playerClass.RootPart;
    
end

function statusPackage:OnExpire()
    if RunService:IsClient() then return end;
    local playerClass = self.PlayerClass;
	if playerClass == nil then return end;

    self.BodyForce.Humanoid.PlatformStand = false;
    
end

return modStatusClass.new(statusPackage);