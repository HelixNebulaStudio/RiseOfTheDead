local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Heavy Bandit";
    HumanoidType = "Bandit";
    
	Configurations = {
        AttackDamage = 20;
        AttackRange = 4;
        AttackSpeed = 1;

        MaxHealth = 100;
        WalkSpeed = 20;
    };
    Properties = {
        IsHostile = true;
        Smart = true;

        TargetableDistance = 128;

        Level = 1;
        ExperiencePool = 35;
        MoneyReward = NumberRange.new(15, 20);

        SprintSpeed = 10;
        WalkSpeed = 6;
    };

    AddComponents = {
        "TargetHandler";
        "DropReward";
        "AttractNpcs";
        "Chat";
        "RandomClothing";
    };
    AddBehaviorTrees = {
        "BanditDefaultTree";
    };

    ThinkCycle = 1;
    
    Chatter = {
        AlertPhrases = {
            {Say="Hasta la vista, noobs";};
            {Say="Hand over the cache!";};
            {Say="Say hello to my little friend!";};
        };
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    local maxHealth = 64000 + 2000 * level;
    configurations.BaseValues.MaxHealth = maxHealth;

    properties.PrimaryWeaponItemId = "minigun";

    local binds = npcClass.Binds;
    function binds.EquipSuccessFunc(toolHandler: ToolHandlerInstance)
        local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
        if equipmentClass == nil then return end;

        if equipmentClass.Class == "Gun" then
            local modifier = equipmentClass.Configurations.newModifier("BanditGun");
            modifier.SetValues.Damage = math.random(1, 2);
            modifier.SetValues.NpcPercentHealthDamage = 0.1;
            equipmentClass.Configurations:AddModifier(modifier, true);

        elseif equipmentClass.Class == "Melee" then
            local modifier = equipmentClass.Configurations.newModifier("BanditMelee");
            modifier.SetValues.Damage = math.random(20, 25);
            modifier.SetValues.NpcPercentHealthDamage = 0.3;
            equipmentClass.Configurations:AddModifier(modifier, true);
        end
    end

    local attractNpcsComp = npcClass:GetComponent("AttractNpcs");
    if attractNpcsComp then
        attractNpcsComp.AttractHumanoidType = {"Zombie"; "Human"; "Bandit"; "Rat"};
        attractNpcsComp.SelfAttractAlert = true;
        attractNpcsComp:Activate();
    end

    task.delay(0.5, function()
        npcClass.RootPart.Anchored = false;
        if properties.Seat == nil then return end;

        local seatPart = properties.Seat;
        npcClass:Sit(seatPart);
    end)

    npcClass:GetComponent("RandomClothing"){
        AddHair = false;
        AddGear = {"Helmet"; "Kneepad"};
    };
end

function npcPackage.Spawned(npcClass: NpcClass)
    npcClass.Garbage:Tag(npcClass.OnThink:Connect(function()
        if npcClass.Humanoid.Sit then return end;

        npcClass.BehaviorTree:RunTree("BanditDefaultTree", true);
    end));
end

return npcPackage;