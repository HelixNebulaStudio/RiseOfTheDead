local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Cultist";
    HumanoidType = "Cultist";
    
	Configurations = {
        AttackDamage = 20;
        AttackRange = 6;
        AttackSpeed = 1;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 256;

        Level = 1;
        BaseExperience = 40;
    };

    AddComponents = {
        "TargetHandler";
        "Chat";
        "AttractNpcs";
        "RandomClothing";
        "FollowPlayer";
        "DynamicLevel";
    };

    Voice = {
        VoiceId = 3;
        Pitch = 1;
        Speed = 1;
        PlaybackSpeed = 1;
    };

    DynamicLevelScaling = {
        WalkSpeed = 15;
        MaxHealth = function(lvl) return 400+(math.max(200*lvl, 400)); end;
        AttackDamage = function(lvl) return math.min(10+(lvl/2), 100); end;
    };

    ThinkCycle = 1;
};

function npcPackage.Spawning(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local configurations: ConfigVariable = npcClass.Configurations;
    local healthComp: HealthComp = npcClass.HealthComp;
end

function npcPackage.Spawned(npcClass: NpcClass)
    npcClass:GetComponent("RandomClothing"){
        Name = npcPackage.Name; 
        AddHair = false;
    };

    npcClass.WieldComp:Equip{
        ItemId = "survivalknife";

        OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
            local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
            if equipmentClass == nil then return end;

            equipmentClass:AddBaseModifier("CultistMelee", {
                SetValues = {
                    Damage = math.random(5, 10);
                    NpcPercentHealthDamage = 0.15;
                };
            });
        end
    };
end

return npcPackage;