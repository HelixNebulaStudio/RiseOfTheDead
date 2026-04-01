local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==

local statusPackage = {
    Id = "EntityLeash";
    Icon = "rbxassetid://10368377851";
    Name = "EntityLeash";
    Description = "";
    Buff = false;
    ExpiresOnDeath = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    statusClass.Values.Ragdoll = true;
    
    local weaponModel = statusClass.Values.WeaponModel;
    local hookPoints = weaponModel.points;

    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass == nil then return end;

    local applyBy: PlayerClass = statusClass.ApplyBy :: PlayerClass;
    if applyBy == nil then return end;
    local player = applyBy:GetInstance();

    local characterModel = characterClass.Character;
    for _, obj in ipairs(characterModel:GetChildren()) do
        if not obj:IsA("BasePart") then continue end;
        obj.CollisionGroup = "Character";
    end
    statusClass.Garbage:Tag(function()
        for _, obj in ipairs(characterModel:GetChildren()) do
            if not obj:IsA("BasePart") then continue end;
            obj.CollisionGroup = "Enemies";
        end
    end)

    local rootPart = characterClass.RootPart;
    rootPart.Massless = true;

    if rootPart:CanSetNetworkOwnership() then
        rootPart:SetNetworkOwner(player);
    end;

    statusClass.Garbage:Tag(weaponModel:GetAttributeChangedSignal("Leashed"):Connect(function()
        if weaponModel:GetAttribute("Leashed") == nil then
            statusClass.IsExpired = true;
        end
    end))
    statusClass.Garbage:Tag(weaponModel:GetPropertyChangedSignal("Parent"):Connect(function()
        if workspace:IsAncestorOf(weaponModel) then return end;
        statusClass.IsExpired = true;
    end))

    for _, hook in pairs(hookPoints:GetChildren()) do
        local targetAtt = characterClass.Character:FindFirstChild(hook.Name, true);
        if targetAtt then
            local newRope = Instance.new("RopeConstraint");
            newRope.Parent = weaponModel;
            newRope.Visible = true;
            newRope.Attachment0 = hook;
            newRope.Attachment1 = targetAtt;
            
            newRope.Length = 4;
            newRope.Color = BrickColor.new(Color3.fromRGB(0, 142, 170));
            statusClass.Garbage:Tag(newRope);
        end
    end
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass == nil then return end;

    local rootPart = characterClass.RootPart;
    rootPart.Massless = false;

    if rootPart:CanSetNetworkOwnership() then
        rootPart:SetNetworkOwner(nil);
    end;
end

return modStatusClass.new(statusPackage);