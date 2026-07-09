local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local npcPackage = {
    Name = "Ticks";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 5;
        AttackSpeed = 2;

        MaxHealth = 50;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 40;
        LockOnExpireDuration = NumberRange.new(2, 3);

        Level = 1;
        BaseExperience = 15;
        DropRewardId = "ticks";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "RandomClothing";
        "DynamicLevel";
        "TickCombustion";
        "ImmunitySkin";
    };
    AddBehaviorTrees = {};

    DynamicLevelScaling = {
        WalkSpeed = 40;
        MaxHealth = function(lvl) return 49+(math.max(50*lvl, 50)); end;
        AttackDamage = function(lvl) return math.min(35+(lvl), 200); end;
    };
};
--==

function npcPackage.Spawning(npcClass: NpcClass)
    local char = npcClass.Character;

    local ticksModel = char:WaitForChild("ExplosiveTickBlobs");
    local tickBlobs = ticksModel:GetChildren();
    
    modTables.Shuffle(tickBlobs);
    for a=1, #tickBlobs do
        if a > 10 then
            game.Debris:AddItem(tickBlobs[a], 0);
            
        else
            tickBlobs[a].Transparency = 0;
            local newSize = math.random(50,350)/1000
            tickBlobs[a].Size = Vector3.new(newSize, newSize);
            
        end
    end
    
    for _, obj in pairs(npcClass.Head:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name == "Blobs" then
            obj.Parent = ticksModel;
        end
    end

    local blobs = {};
    for _, obj in ipairs(char.UpperTorso:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name == "Blobs" then
            table.insert(blobs, obj);
        end
    end
    char:GetAttributeChangedSignal("DetonationTime"):Connect(function()
        for _, blob in ipairs(blobs) do
            blob.Material = char:GetAttribute("DetonationTime") and Enum.Material.Neon or Enum.Material.Foil;
        end
    end)
    npcClass.Garbage:Tag(function()
        char:SetAttribute("DetonationTime", nil);
    end)

    npcClass:GetComponent("RandomClothing")();
    npcClass:GetComponent("TickCombustion").CombustOnDeath = false;
end


return npcPackage;