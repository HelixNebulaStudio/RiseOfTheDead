local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Rat";
    HumanoidType = "Rat";
    
	Configurations = {};
    Properties = {
        Level = 1;
        ResourceDropId = "rat";
        MoneyReward = NumberRange.new(2, 4);
        ExperiencePool = 40;
        IsHostile = false;
    };

    Chatter = {
        AlertPhrases= {
            {Say="Looks like the zombies are here!"; HumanoidType="Zombie";};
            {Say="Hostiles!!";};
        };
        KillPhrases = {
            {Say="Target eliminated!"};
            {Say="Another one put back into the ground!"; HumanoidType="Zombie";};
            {Say="Go back to starve bandits!"; HumanoidType="Bandit";};
        };
        HuntSpeech = {
            {Say="Come out, come out~!"};
            {Say="There's no use hiding!"};
        };
        PatrolConverse = {
            {
                Say="Hey, weren't you suppose to restock the warehouse?"; 
                Reply="Yeah.. Had an emergency in the toilet, must've been the grey cabbage I ate.";
                SayAnimations = {"shrug2";};
                ReplyAnimations = {"nodyes";};
            };
            {
                Say="Hey, hear this. Why did a Bandit leave his door open..? So he doesn't have to break into the place again.";
                Reply="Haha, good one.";
                ReplyAnimations = {"laugh";};
            };
        };
    };
    
    AddComponents = {
        "TargetHandler";
        "DropReward";
        "AttractNpcs";
        "Chat";
        "RandomClothing";
    };

    Voice = {
        VoiceId = NumberRange.new(1, 7);
        Pitch = NumberRange.new(-3, 2);
        Speed = NumberRange.new(0.98, 1.02);
        PlaybackSpeed = NumberRange.new(0.98, 1.02);
    };
    
    ThinkCycle = 1;
};

function npcPackage.Spawning(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local maxHealth = 400 + 200*(properties.Level-1);
    npcClass.HealthComp.MaxHealth = maxHealth;
    npcClass.HealthComp.CurHealth = maxHealth;
    
    local level = math.max(properties.Level, 0);
    
    properties.LastSeenMemDuration = 5 + (level/20) * math.random(0, 100)/100;
    properties.LastPosMemDuration = 40 + (level/3) * math.random(0, 100)/100;

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
            equipmentClass:AddBaseModifier("RatGun", {
                SetValues = {
                    Damage = math.random(3, 5);
                    MaxAmmoLimit = math.random(60, 120);
                    NpcPercentHealthDamage = 0.1;
                };
            });

        elseif equipmentClass.Class == "Melee" then
            equipmentClass:AddBaseModifier("RatMelee", {
                SetValues = {
                    Damage = math.random(10, 15);
                    NpcPercentHealthDamage = 0.3;
                };
            });

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

    npcClass:GetComponent("RandomClothing")();
end

function npcPackage.Despawning(npcClass: NpcClass)
end

return npcPackage;