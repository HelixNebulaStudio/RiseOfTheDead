local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local statusPackage = {
    Id = "ShadowStrangle";
    Icon = "rbxassetid://107896812314629";
    Name = "Shadow Strangle";
    Description = "You are being strangled by Shadow";
    Buff = false;
    ExpiresOnDeath = true;
};

function statusPackage.init()
    local shadowStrangleArm = game.ReplicatedStorage.Prefabs.NpcAbilities.ShadowStrangleArm;
    statusPackage.ShadowStrangleArm = shadowStrangleArm;
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass.ClassName ~= "PlayerClass" then return end;

    local playerClass: PlayerClass = characterClass :: PlayerClass;
    local playerChar = playerClass.Character;

	local statusComp: StatusComp = statusClass.StatusComp;

    local groundPart, originPosition = playerClass:CastGroundRay(64);
    if groundPart == nil then
        originPosition = playerClass:GetCFrame().Position;
    end

    local originAnchor = Debugger:Point(originPosition);
    originAnchor.Parent = workspace.Terrain;

    local oAtt = Instance.new("Attachment");
    oAtt.Parent = originAnchor;

    local rope = Instance.new("RopeConstraint");
    rope.Attachment0 = playerChar.PrimaryPart.RootRigAttachment;
    rope.Attachment1 = oAtt;
    rope.Visible = false;
    rope.Length = 8;
    rope:SetAttribute("FPIgnore", true);
    rope.Parent = originAnchor;

    local newArm = statusPackage.ShadowStrangleArm:Clone();

    local weld = Instance.new("Motor6D");
    weld.Parent = newArm;
    weld.Part0 = newArm:WaitForChild("PrimaryPart");
    weld.Part1 = playerChar.Head;

    newArm.Parent = playerChar;

    statusClass.Garbage:Tag(newArm);
    statusClass.Garbage:Tag(originAnchor);
    statusClass.Garbage:Tag(rope);

    statusComp:Apply("AntiGravity", {
        Values = {
            Amount = 1000;
        };
    });
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
	local statusComp: StatusComp = statusClass.StatusComp;
    statusComp:Apply("AntiGravity", nil);
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms100 ~= true then return end;

    if statusClass.Values.ShadowHealth and statusClass.Values.ShadowHumanoid then
        local shadowHealth = statusClass.Values.ShadowHealth;
        local shadowHumanoid = statusClass.Values.ShadowHumanoid;

        if shadowHumanoid.Health < shadowHealth then
            statusClass.IsExpired = true;
            return;
        end
    end

    if tickData.ms1000 ~= true then return end;
    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass.ClassName ~= "PlayerClass" then return end;

    local healthComp: HealthComp = characterClass.HealthComp;
    healthComp:TakeDamage(DamageData.new{
        Damage = 1;
        DamageType = "IgnoreArmor";
    });
end


return modStatusClass.new(statusPackage);