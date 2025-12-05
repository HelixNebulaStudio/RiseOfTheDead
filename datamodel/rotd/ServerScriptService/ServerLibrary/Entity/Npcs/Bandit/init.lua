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
        IsHostile = false;
    };

    Chatter = {
        AlertPhrases= {
            {Say="Watch out, Zombies!"; HumanoidType="Zombie";};
            {Say="Guns out!";};
            {Say="Enemies!!";};
            {Say="Hostiles in sight!";};
            {Say="We got company!";};
            {Say="They're here! Get ready!";};
            {Say="Look alive people!";};
            {Say="Incoming!";};
            {Say="Time to earn our pay!";};
            {Say="Got movement!"; HumanoidType="Zombie";};
            {Say="Survivors spotted!"; HumanoidType="Human";};
            {Say="More rats to exterminate!"; HumanoidType="Rat";};
        };
        KillPhrases = {
            {Say="Back off, zombies!"; HumanoidType="Zombie";};
            {Say="Can't catch me lacking, losers!";};
            {Say="Brain check, uh oooh, brain dead!"; HumanoidType="Zombie";};
            {Say="Who wants a piece of this?!";};
            {Say="Another one bites the dust!"; HumanoidType="Zombie";};
            {Say="You better be worthy of my bullet!"};
            {Say="Look ma, no hands! Literally!"};
            {Say="Slice and dice ya!"};
            {Say="..and stay dead!"; HumanoidType="Zombie";};
            {Say="That's what you get for messing with us!"};
            {Say="Rest in pieces!"; HumanoidType="Zombie";};
            {Say="Should've stayed in your hole, rat!"; HumanoidType="Rat";};
            {Say="Too slow, too dead!"};
            {Say="Target eliminated, next!"};
            {Say="That's how we do business!"};
            {Say="Clean kill, if I do say so myself."};
            {Say="You picked the wrong bandit to mess with!"};
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
            {
                Say="Remember when we used to work normal jobs?";
                Reply="Ha! This pays better and it's way more fun.";
            };
            {
                Say="Think the boss will give us a raise?";
                Reply="Sure, right after zombies learn to dance.";
            };
            {
                Say="Found any good loot lately?";
                Reply="Nah, slim pickings these days. Everyone's getting smarter about hiding their stuff.";
            };
            {
                Say="You hear about that survivor who took out our forest camp?";
                Reply="Yeah, boss is offering a big reward for their head.";
            };
            {
                Say="Ever wonder if we're on the wrong side of this?";
                Reply="Having second thoughts? Better not let the boss hear that.";
            };
            {
                Say="What's the status on those medical supplies we raided?";
                Reply="Locked up tight at base. Boss says they're worth their weight in gold now.";
            };
            {
                Say="Remember the good old days before the outbreak?";
                Reply="Yeah, but there's no going back now. This is our life.";
            };
            {
                Say="What's the plan for tonight?";
                Reply="Same as always. Raid, loot, repeat.";
            };
            {
                Say="You took my share from the last raid!";
                Reply="Did not! Maybe you should count better next time.";
            };
            {
                Say="That shot you took almost hit me!";
                Reply="Well, maybe don't stand so close to the target next time!";
            };
            {
                Say="Stop stealing my kills!";
                Reply="Not my fault I'm faster on the trigger than you.";
            };
            {
                Say="You're supposed to be watching my back!";
                Reply="And miss all the action up front? No way!";
            };
            {
                Say="That was my target zone to patrol!";
                Reply="Boss never assigned zones. First come, first serve!";
            };
            {
                Say="Did you raid the food storage again?";
                Reply="Hey, a growing bandit needs their snacks!";
            };
            {
                Say="Who ate all the canned beef?";
                Reply="Not me! But whoever did better share next time.";
            };
            {
                Say="These rations are getting worse by the day.";
                Reply="Better than starving. Remember when we had actual fresh food?";
            };
            {
                Say="How come we got new rifles but still eating expired beans?";
                Reply="Boss says firepower feeds the soul... or something like that.";
            };
            {
                Say="We spent the food budget on more ammo again?";
                Reply="Hey, can't eat if you're dead! Besides, bullets taste better than those rations anyway.";
            };
            {
                Say="Another weapons shipment? What about actual food supplies?";
                Reply="You know the motto - more guns, less buns! ...I'm starting to think the boss has priorities mixed up.";
            };
            {
                Say="Heard those Rats are expanding their trade routes.";
                Reply="Yeah, sneaky merchants. Making a fortune while we do the dirty work.";
            };
            {
                Say="Think we should hit one of those Rat caravans?";
                Reply="Boss says they're off limits. Something about 'maintaining business relations'.";
            };
            {
                Say="Those Rats charged me double for basic supplies!";
                Reply="That's their game. They know we need their stuff, so they bleed us dry.";
            };
            {
                Say="Ever notice how the Rats always have the best gear?";
                Reply="Sure do. Bet they're hoarding the good stuff for themselves.";
            };
            {
                Say="Just took down Fumes, that fumes cloud is no joke!";
                Reply="Better than dealing with Tanker. Lost my favorite jacket to that hunk.";
            };
            {
                Say="Ever seen Shadow? Creepy creature.";
                Reply="Yeah, one second they're there, next they're behind you. Hate those things.";
            };
            {
                Say="Remember that Mothena nest we found?";
                Reply="Don't remind me. That dead flying bug gave me nightmares for weeks.";
            };
            {
                Say="That Tanker almost got me yesterday!";
                Reply="Should've seen me last week, had to outrun both Fumes AND Shadow.";
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
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    local maxHealth = 400 + 200*(level-1);
    configurations.BaseValues.MaxHealth = maxHealth;
    
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
            modifier.SetValues.NpcPercentHealthDamage = 0.1;
            equipmentClass.Configurations:AddModifier(modifier, true);

        elseif equipmentClass.Class == "Melee" then
            local modifier = equipmentClass.Configurations.newModifier("BanditMelee");
            modifier.SetValues.Damage = math.random(10, 15);
            modifier.SetValues.NpcPercentHealthDamage = 0.3;
            equipmentClass.Configurations:AddModifier(modifier, true);
        end
    end

    npcClass.Garbage:Tag(npcClass.OnThink:Connect(function()
        npcClass.BehaviorTree:RunTree("BanditDefaultTree", true);
    end));

    local attractNpcsComp = npcClass:GetComponent("AttractNpcs");
    if attractNpcsComp then
        attractNpcsComp.AttractHumanoidType = {"Zombie"; "Human"; "Bandit"; "Rat"};
        attractNpcsComp.SelfAttractAlert = true;
        attractNpcsComp:Activate();
    end

    npcClass:GetComponent("RandomClothing")();
end

function npcPackage.Despawning(npcClass: NpcClass)
end

return npcPackage;