local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Bandit";
    HumanoidType = "Bandit";
    
	Configurations = {};
    Properties = {
        Level=1;
        ResourceDropId = "bandit";
        MoneyReward={Min=2; Max=4};
        ExperiencePool=40;
        IsHostile = true;
    };

    Chatter = {
        Greetings = {
            "Back off, zombies!";
            "Can't catch me, losers!";
            "Brain check, uh oooh, brain dead!";
            "Who wants a piece of this?!";
            "Another one bites the dust!";
            "You better be worthy of my bullet!";
            "Look ma, no hands! Literally!";
            "Slice and dice ya!";
            "..and stay dead!";
        };
    };
    
    AddComponents = {
        "TargetHandler";
        "DropReward";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local maxHealth = 400 + 200*(properties.Level-1);
    npcClass.HealthComp.MaxHealth = maxHealth;
    npcClass.HealthComp.CurHealth = maxHealth;
    
    local weaponChoices = {"machete"; "tec9"; "xm1014";};
    if properties.Level > 5 then
        table.insert(weaponChoices, "ak47");
    elseif properties.Level > 10 then
        table.insert(weaponChoices, "dualp250");
    elseif properties.Level > 20 then
        table.insert(weaponChoices, "fnfal");
    end
    
    properties.PrimaryWeaponItemId = weaponChoices[math.random(1, #weaponChoices)];

    local binds = npcClass.Binds;
    function binds.EquipSuccessFunc(toolHandler: ToolHandlerInstance)
        local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
        if equipmentClass == nil then return end;

        if equipmentClass.Class == "Gun" then
            local modifier = equipmentClass.Configurations.newModifier("BanditGun");
            modifier.SetValues.Damage = math.random(3, 5);
            modifier.SetValues.AmmoCapacity = math.random(60, 120);
            equipmentClass.Configurations:AddModifier(modifier, true);

        elseif equipmentClass.Class == "Melee" then
            local modifier = equipmentClass.Configurations.newModifier("BanditMelee");
            modifier.SetValues.Damage = math.random(10, 15);
            equipmentClass.Configurations:AddModifier(modifier, true);
        end
    end

    npcClass.Garbage:Tag(npcClass.OnThink:Connect(function()
        --npcClass:GetComponent("StatusProcess")();
        npcClass.BehaviorTree:RunTree("BanditDefaultTree", true);
    end));
end

function npcPackage.Despawning(npcClass: NpcClass)
end

return npcPackage;