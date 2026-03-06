local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id = "NightVision";
    Icon = "rbxassetid://6008673515";
    Name = "Night Vision Mode";
    Description = "Dark areas are lit up by infrared light.";
    Buff = true;
};

function statusPackage.onRequire()
    if RunService:IsClient() then
		modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);
    end
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then 
        if game.Lighting:GetAttribute("DarkAmbient") == nil then
            game.Lighting:SetAttribute("DarkAmbient", Color3.fromRGB(0, 255, 0));
        end

        return;
    end;
    if tickData.ms100 == false then return end;
    
    local modifierId = statusClass.Values.ModifierId;
    if modifierId == nil then return end;

    local playerClass: PlayerClass = statusClass.StatusOwner :: PlayerClass;
    local modifier: ItemModifierInstance? = playerClass.WieldComp:GetOrDefaultItemModifier(modifierId);
    if modifier == nil or modifier.Enabled == false then
        statusClass.IsExpired = true;
        return;
    end
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    game.Lighting:SetAttribute("DarkAmbient", nil);
end

return modStatusClass.new(statusPackage);