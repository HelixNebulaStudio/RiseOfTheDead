local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Russell";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        PrimaryGunItemId = "minigun";
        MeleeItemId = "fireaxe";
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
        VoiceId = 7;
        Pitch = -3;
        Speed = 1;
        PlaybackSpeed = 1.05;
    };

    SurvivorIdleData = {
        ["Warehouse Safehouse"] = {
            Data = {
                RestTimeInterval = NumberRange.new(90, 160);
                RestingSeatName = "RussellSeat";
                RestDuration = NumberRange.new(20, 29);
                RestSay = {
                    "*Zzz... zzz.. zzz..*";
                    "*grumbles in sleep* Can't get any peace and quiet around here..";
                };
            };

            warehouseSafehouseStorage = {
                Chance = 1;
                Say = {
                    "Who's been messing with my storage organization?";
                    "*grumbles* Everything's in the wrong place again..";
                    "This place is a mess. Nobody respects proper storage protocol.";
                    "If someone takes my stuff without asking again...";
                    "Can't believe I have to reorganize this mess. Again.";
                };
                Duration = NumberRange.new(20, 30);
            };
            warehouseWorkbench = {
                Chance = 1;
                Say = {
                    "*grumbles* These modifications better be worth my time..";
                    "Who keeps leaving their tools all over MY workbench?";
                    "If someone touched my minigun again, I swear...";
                    "*mutters* Can't even work in peace around here.";
                    "This would go faster if people stopped interrupting me.";
                    "These parts aren't going to assemble themselves...";
                };
                Duration = NumberRange.new(34, 40);
            };
            warehouseShop = {
                Chance = 0.5;
                Say = {
                    "*grumbles* Jesse, you better have what I need this time.";
                    "Wake up, Jesse! I don't have all day to wait around.";
                    "*impatiently* If you're out of stock again, I'm not going to be happy.";
                    "This better not be a waste of my time, Jesse.";
                    "*mutters* Why do I even bother coming here...";
                };
                Duration = NumberRange.new(30, 34);
            };
            warehouseVendingMachine = {
                Chance = 0.5;
                Say = {
                    "*glares at machine* This better not eat my money again...";
                    "Maintenance on this thing is overdue. Typical.";
                    "*grumbles* Why do we even keep this unreliable piece of junk?";
                    "If this machine gives me another useless item...";
                    "The quality control on these supplies is abysmal.";
                    "*inspects machine skeptically* Everything's falling apart these days.";
                };
                InteractSay = {
                    "*scoffs* A $ItemId? What a waste of perfectly good money.";
                    "*glares at $ItemId* This is exactly why I hate these machines.";
                    "Great. Another $ItemId to add to the pile of useless junk.";
                    "*examines $ItemId with disdain* Quality standards have really gone downhill.";
                    "Hmph. $ItemId... Not even worth the metal it's made from.";
                    "*grumbles* Five hundred dollars for a $ItemId? Highway robbery.";
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