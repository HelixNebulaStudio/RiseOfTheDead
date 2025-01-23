local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="Stun";
    Icon="rbxassetid://4467439850";
    Name="Stunned";
    Description="Stunned";
    Buff=false;
    Tags = {"Mobility"; "Stun";};
    Cleansable=true;
};

function statusPackage:OnApply()
    if RunService:IsServer() then return end;
    local playerClass = self.PlayerClass;
    
    local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    local animator = playerClass.Humanoid:WaitForChild("Animator");
    local track = animator:LoadAnimation(script.Stun);
    track:Play(0.25);
    self.StunAnim = track;

    modCharacter.CharacterProperties.CanMove = false;
    modCharacter.CharacterProperties.CanAction = false;
    modCharacter.MouseProperties.Mouse1Down = false;
    modCharacter.MouseProperties.Mouse2Down = false;
    modCharacter.UpdateWalkSpeed();
end

function statusPackage:OnExpire()
    if RunService:IsServer() then return end;
    
    local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    if self.StunAnim then
        self.StunAnim:Stop(0.25);
    end

    modCharacter.CharacterProperties.CanMove = true;
    modCharacter.CharacterProperties.CanAction = true;
    modCharacter.UpdateWalkSpeed();
end

return modStatusClass.new(statusPackage);