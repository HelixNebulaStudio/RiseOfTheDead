local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local statusSetWalkspeed = shared.require(script.Parent.SetWalkspeed);
--==
local statusPackage = {
    Id="Superspeed";
    Icon="rbxassetid://6121470569";
    Name="Superspeed";
    Description="Grant you temporary super speed.";
    Buff=true;
    Cleansable=true;
    ExpiresOnDeath=true;
};


function statusPackage.BindApply(statusClass: StatusClassInstance)
    statusClass.Values.Amount = 40;
    statusSetWalkspeed.BindApply(statusClass);

    if RunService:IsClient() then return end;
    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil then return end;

    local character = characterClass.Character;

    local function addTrail(part)
        local attA = part:FindFirstChild("SpeedTrailAtt01") or Instance.new("Attachment");
        attA.Name = "SpeedTrailAtt01";
        attA.Position = Vector3.new(0, -0.2, 0);
        attA.Parent = part;
        statusClass.Garbage:Tag(attA);

        local attB = part:FindFirstChild("SpeedTrailAtt02") or Instance.new("Attachment");
        attB.Name = "SpeedTrailAtt02";
        attB.Position = Vector3.new(0, 0.2, 0);
        attB.Parent = part;
        statusClass.Garbage:Tag(attB);

        local newTrail = part:FindFirstChild("SpeedTrail") or script.SpeedTrail:Clone();
        newTrail.Attachment0 = attA;
        newTrail.Attachment1 = attB;
        newTrail.Parent = part;
        statusClass.Garbage:Tag(newTrail);
    end

    if character:FindFirstChild("LowerTorso") then
        addTrail(character.LowerTorso);
    end
    if character:FindFirstChild("LeftHand") then
        addTrail(character.LeftHand);
    end
    if character:FindFirstChild("RightHand") then
        addTrail(character.RightHand);
    end
    if character:FindFirstChild("LeftFoot") then
        addTrail(character.LeftFoot);
    end
    if character:FindFirstChild("RightFoot") then
        addTrail(character.RightFoot);
    end
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    statusSetWalkspeed.BindExpire(statusClass);
end


return modStatusClass.new(statusPackage);