local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Rat";
    HumanoidType = "Rat";
    
	Configurations = {};
    Properties = {
        Level=1;
        ResourceDropId = "rat";
        MoneyReward={Min=2; Max=4};
        ExperiencePool=40;
        IsHostile = false;
    };

    Chatter = {
        AlertPhrases= {
            {Say="Enemies!!";};
        };
        KillPhrases = {
            {Say="Target eliminated!"};
        };
        PatrolConverse = {
            {
                Say="Hey, did you hear about the new safehouse?"; 
                Reply="Yeah, bunch of survivors holed up there. Easy pickings if you ask me.";
                SayAnimations = {"shrug2";};
                ReplyAnimations = {"nodyes";};
            };
            {
                Say="Keep your eyes peeled, heard a squadron went missing.";
                Reply="Probably those #### survivors getting bold again.";
            };
        };
    };
    
    AddComponents = {
        "TargetHandler";
        "DropReward";
        "AttractNpcs";
        "Chat";
    };

    Voice = {
        VoiceId = NumberRange.new(1, 7);
        Pitch = NumberRange.new(-3, 2);
        Speed = NumberRange.new(0.98, 1.02);
        PlaybackSpeed = NumberRange.new(0.98, 1.02);
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local maxHealth = 400 + 200*(properties.Level-1);
    npcClass.HealthComp.MaxHealth = maxHealth;
    npcClass.HealthComp.CurHealth = maxHealth;
    
    local weaponChoices = {"spikedbat"; "m9legacy"; "mariner590";};
    if properties.Level > 5 then
        table.insert(weaponChoices, "m4a4");
    elseif properties.Level > 10 then
        table.insert(weaponChoices, "deagle");
    elseif properties.Level > 20 then
        table.insert(weaponChoices, "fnfal");
    end
    
    properties.PrimaryWeaponItemId = weaponChoices[math.random(1, #weaponChoices)];

    local binds = npcClass.Binds;
    function binds.EquipSuccessFunc(toolHandler: ToolHandlerInstance)
        local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
        if equipmentClass == nil then return end;

        if equipmentClass.Class == "Gun" then
            local modifier = equipmentClass.Configurations.newModifier("RatGun");
            modifier.SetValues.Damage = math.random(3, 5);
            modifier.SetValues.AmmoCapacity = math.random(60, 120);
            modifier.SetValues.NpcPercentHealthDamage = 0.1;
            equipmentClass.Configurations:AddModifier(modifier, true);

        elseif equipmentClass.Class == "Melee" then
            local modifier = equipmentClass.Configurations.newModifier("RatMelee");
            modifier.SetValues.Damage = math.random(10, 15);
            modifier.SetValues.NpcPercentHealthDamage = 0.3;
            equipmentClass.Configurations:AddModifier(modifier, true);
        end
    end

    npcClass.Garbage:Tag(npcClass.OnThink:Connect(function()
        npcClass.BehaviorTree:RunTree("RatDefaultTree", true);
    end));

    local attractNpcsComp = npcClass:GetComponent("AttractNpcs");
    if attractNpcsComp then
        attractNpcsComp.AttractHumanoidType = {"Zombie"; "Rat"; "Bandit"};
        attractNpcsComp.SelfAttractAlert = true;
        attractNpcsComp:Activate();
    end
end

function npcPackage.Despawning(npcClass: NpcClass)
end

return npcPackage;