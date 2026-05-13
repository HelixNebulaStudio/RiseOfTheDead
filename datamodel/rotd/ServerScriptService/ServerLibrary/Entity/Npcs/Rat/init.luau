local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Rat";
    HumanoidType = "Rat";

	Configurations = {};
    Properties = {
        BasicEnemy = true;
        Level = 1;
        MoneyReward = NumberRange.new(2, 4);
        ExperiencePool = 40;
        IsHostile = false;
        DropRewardId = "rat";
    };

    Chatter = {
        AlertPhrases= {
            {Say="Looks like the zombies are here!"; HumanoidType="Zombie";};
            {Say="Another dead walking"; HumanoidType="Zombie";};
            {Say="Survivors spotted!"; HumanoidType="Human";};
            {Say="Bandits!"; HumanoidType="Bandit";};
            {Say="Hostiles!!";};
            {Say="We got a pest over here!";};
            {Say="Lock n' loaded!";};
            {Say="You're dead now..";};
            {Say="Your time's up buddy!";};
        };
        KillPhrases = {
            {Say="Target down!"};
            {Say="Another one back into the ground!"; HumanoidType="Zombie";};
            {Say="Go home and starve bandits!"; HumanoidType="Bandit";};
            {Say="Night night!"};
            {Say="Ugh, this one splashed guts all over me!"; HumanoidType="Zombie";};
            {Say="Go cry to Zark!"; HumanoidType="Bandit";};
            {Say="Sleep tight!"};
            {Say="What a noob.."};
            {Say="See ya later, alligator~"};
        };
        HuntSpeech = {
            {Say="Come out, come out~!"};
            {Say="There's no use hiding!"};
            {Say="I heard you.. C'mon out!"};
            {Say="You're dead when I find you!"};
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
            {
                Say="Can't believe I have to patrol the sewers again.";
                Reply="Yeah, we may be the Rats, but that doesn't mean we like the sewers..";
            };
            {
                Say="Why don't we just steal from survivors like the bandits?";
                Reply="What, you think there're unlimited survivors to steal from?";
            };
            {
                Say="Any idea when's the next shipment coming in?";
                Reply="Probably by the end of the week, at least that's what my friend in the navy rat told me.";
            };
            {
                Say="It would be so nice to be a shop keeper one day..";
                Reply="I hear someone sold 4 stacks of purple lemons to one of them for no reason.";
            };
            {
                Say="I think we're running low on walkie talkies again.";
                Reply="Yep, looks like the price is going up for a while.";
            };
        };
        FleeSpeech = {
            {Say="Stop!!"};
            {Say="You win this time!"};
            {Say="I'm out!"};
            {Say="Let me go, please!"};
        };
        DeadbodySpeech = {
            {Say="What the?!"};
            {Say="We are under attack!"};
            {Say="Uh oh!"};
            {Say="Huh?!"};
            {Say="Holy!"};
            {Say="Nooo!"};
        };
    };
    
    AddComponents = {
        "TargetHandler";
        "DropReward";
        "AttractNpcs";
        "Chat";
        "RandomClothing";
        "DynamicLevel";
    };

    Voice = {
        VoiceId = NumberRange.new(1, 7);
        Pitch = NumberRange.new(-3, 2);
        Speed = NumberRange.new(0.98, 1.02);
        PlaybackSpeed = NumberRange.new(0.98, 1.02);
    };
    
    ThinkCycle = 1;

    DynamicLevelScaling = {
        MaxHealth = function(lvl) return 200+(math.max(200*lvl, 200)); end;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local properties = npcClass.Properties;
    
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
                ProductValues = {
                    Rpm = 1/2;
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
    
    npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
        if not isDead then return end;
        
        local lastDamageBy: EntityClass? = npcClass.HealthComp.LastDamagedBy;
        local deathPos = npcClass:GetCFrame().Position;
        local nearbyNpcClasses, nearbyDistances = shared.modNpcs.Octree:RadiusSearch(deathPos, 32);

        for a=1, #nearbyNpcClasses do
            local allyNpcClass: NpcClass = nearbyNpcClasses[a];
            if allyNpcClass.HealthComp.IsDead then continue end;
            if allyNpcClass.HumanoidType ~= npcClass.HumanoidType then continue end;
            if not allyNpcClass:IsInVision(npcClass.Character) then continue end;

            allyNpcClass.Properties.SeenDeadbodyData = {
                SeenTick = tick();
                Position = deathPos;
                KillerCharacter = lastDamageBy and lastDamageBy.Character or nil;
            };
            
            if lastDamageBy then
                local allyTargetHandlerComp = allyNpcClass:GetComponent("TargetHandler");
                if allyTargetHandlerComp then
                    allyTargetHandlerComp:AddTarget(lastDamageBy.Character);
                end
            end
        end
    end)
end

function npcPackage.Despawning(npcClass: NpcClass)
end

return npcPackage;