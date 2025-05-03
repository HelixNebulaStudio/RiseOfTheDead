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
        Hostile = true;
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
        "IsInVision";
        "DropReward";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local maxHealth = 400 + 200*(properties.Level-1);
    npcClass.HealthComp.MaxHealth = maxHealth;
    npcClass.HealthComp.CurHealth = maxHealth;
    

    local weaponChoices = {"tec9"; "xm1014";};
    if properties.Level > 5 then
        table.insert(weaponChoices, "ak47");
    elseif properties.Level > 10 then
        table.insert(weaponChoices, "dualp250");
    elseif properties.Level > 20 then
        table.insert(weaponChoices, "fnfal");
    end
    if properties.WeaponId == nil then
        properties.WeaponId = weaponChoices[math.random(1, #weaponChoices)];
    end
    
    
    npcClass.Garbage:Tag(npcClass.OnThink:Connect(function()
        Debugger:Warn("Bandit thinking..");
        npcClass.BehaviorTree:RunTree("BanditDefaultTree", true);
    end)); 
end

function npcPackage.Spawned(npcClass: NpcClass)
end


return npcPackage;