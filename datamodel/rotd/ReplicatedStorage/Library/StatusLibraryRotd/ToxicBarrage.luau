local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="ToxicBarrage";
    Icon="";
    Name="Toxic Barrage";
    Description="Reduced immunity";
    Buff=true;
};

local faces = {Enum.NormalId.Back; Enum.NormalId.Bottom; Enum.NormalId.Front; Enum.NormalId.Left; Enum.NormalId.Right; Enum.NormalId.Top;};
function statusPackage.OnApply(statusClass: StatusClassInstance)
    statusClass.Values.ImmunityReduction = statusClass.Values.ImmunityReduction or 0.5;

    local toxinTexture = game.ReplicatedStorage.Prefabs.Textures:WaitForChild("ToxinTexture");

    local characterClass : CharacterClass = statusClass.StatusOwner;
    if characterClass.Character == nil then return end;

    local bodyParts = characterClass.Character:GetChildren();
    for a=1, #bodyParts do
        if bodyParts[a]:IsA("BasePart") and bodyParts[a].Name ~= "HumanoidRootPart" and bodyParts[a].Transparency ~= 1 then
            for b=1, #faces do
                local new = toxinTexture:Clone();
                new.Face = faces[b];
                new.Parent = bodyParts[a];
                statusClass.Garbage:Tag(new);
            end
        end
    end
    
end

return modStatusClass.new(statusPackage);