local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="NightVision";
    Icon="rbxassetid://6008673515";
    Name="Night Vision Mode";
    Description="Dark areas are lit up by infrared light.";
    Buff=true;
};

function statusPackage.OnApply(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    local function setNV()
        local h, s, v = game.Lighting.OutdoorAmbient:ToHSV();
        game.Lighting.Ambient = Color3.fromRGB(0, math.max(128, v*255), 0);
    end

    statusClass.Garbage:Tag(game.Lighting:GetPropertyChangedSignal("Ambient"):Connect(setNV))
    statusClass.Garbage:Tag(game.Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(setNV));
    setNV();
end

function statusPackage.OnExpire(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    game.Lighting.Ambient = Color3.fromRGB(10, 10, 10);
end

return modStatusClass.new(statusPackage);