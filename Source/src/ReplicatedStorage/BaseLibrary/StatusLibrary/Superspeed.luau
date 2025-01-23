local RunService = game:GetService("RunService");
local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local statusSetWalkspeed = require(script.Parent.SetWalkspeed);
--==
local statusPackage = {
    Id="Superspeed";
    Icon="rbxassetid://6121470569";
    Name="Superspeed";
    Description="Grant you temporary super speed.";
    Buff=true;
    Cleansable=true;
};


function statusPackage:OnApply()
    self.Amount = 40;
    statusSetWalkspeed.OnApply(self);

    if RunService:IsClient() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;
    
    local character = playerClass.Character;

    local function addTrail(part)
        local attA = part:FindFirstChild("SpeedTrailAtt01") or Instance.new("Attachment");
        attA.Name = "SpeedTrailAtt01";
        attA.Position = Vector3.new(0, -0.2, 0);
        attA.Parent = part;
        self.Garbage:Tag(attA);

        local attB = part:FindFirstChild("SpeedTrailAtt02") or Instance.new("Attachment");
        attB.Name = "SpeedTrailAtt02";
        attB.Position = Vector3.new(0, 0.2, 0);
        attB.Parent = part;
        self.Garbage:Tag(attB);

        local newTrail = part:FindFirstChild("SpeedTrail") or script.SpeedTrail:Clone();
        newTrail.Attachment0 = attA;
        newTrail.Attachment1 = attB;
        newTrail.Parent = part;
        self.Garbage:Tag(newTrail);
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

function statusPackage:OnExpire()
    statusSetWalkspeed.OnExpire(self);
end


return modStatusClass.new(statusPackage);