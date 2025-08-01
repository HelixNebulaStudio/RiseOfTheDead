local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local npcPackage = {
    Name = "Stephanie";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        PrimaryGunItemId = "dualp250";
        MeleeItemId = "machete";
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "AttractNpcs";
    };
    AddBehaviorTrees = {
        "SurvivorIdleTree";
        "SurvivorCombatTree";
    };

    Voice = {
        VoiceId = 2;
        Pitch = -3;
        Speed = 1;
        PlaybackSpeed = 1;
    };

    SurvivorIdleData = {
        ["Warehouse Safehouse"] = {
            Data = {
                RestTimeInterval = NumberRange.new(90, 160);
                RestingSeatName = "StephanieSeat";
                RestDuration = NumberRange.new(19, 29);
                RestSay = {
                    "Ropes.. check. Ammunition.. check. Guns.. oh..";
                    "Hmmm.. should I check the shelves again..? nah.";
                    "Maybe this would work.. oh wait, no...";
                    "Mixing sulfur with the.. hmm.. Maybe that's not a good idea..";
                };
            };

            warehouseSafehouseStorage = {
                Chance = 1;
                Say = {
                    "Let's see what we have in storage today..";
                    "Where did I put those explosive materials..";
                    "Need to keep track of our ammunition stock..";
                    "*mumbles* Gunpowder, check... primers, check...";
                };
                Duration = NumberRange.new(20, 30);
            };
            warehouseWorkbench = {
                Chance = 1;
                Say = {
                    "Time to give these pistols some extra kick..";
                    "These dual pistols need some modifications..";
                    "Maybe I should add some extended mags to these..";
                    "*checking blueprints* This mod should work perfectly..";
                    "These pistols could use some upgrades..";
                };
                Duration = NumberRange.new(34, 40);
            };
            warehouseShop = {
                Chance = 0.5;
                Say = {
                    "Jesse! Wake up!";
                    "Got any deals for me today Jesse?";
                    "Hey, I need some supplies for my modifications..";
                    "I'm running low on ammunition, pistol ammo specifically.";
                };
                Duration = NumberRange.new(30, 34);
            };
            warehouseVendingMachine = {
                Chance = 0.5;
                Say = {
                    "I need something to keep me awake while working on these mods..";
                    "Maybe I'll get lucky and find some weapon parts in here..";
                    "*examines machine* The wiring on this thing looks sketchy..";
                };
                InteractSay = {
                    "A $ItemId? That's... not what I expected.";
                    "Huh, this machine keeps surprising me with these $ItemIds.";
                    "Well, a $ItemId is better than nothing I suppose.";
                    "*stares at $ItemId* This machine needs maintenance...";
                    "Not exactly what I wanted, but this $ItemId might be useful.";
                };
                InteractTime = -4;
                Duration = NumberRange.new(14, 20);
            };
        };
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local attractNpcsComp = npcClass:GetComponent("AttractNpcs");
    if attractNpcsComp then
        attractNpcsComp.AttractHumanoidType = {"Zombie"};
        attractNpcsComp.SelfAttractAlert = true;
        attractNpcsComp:Activate();
    end
end

return npcPackage;