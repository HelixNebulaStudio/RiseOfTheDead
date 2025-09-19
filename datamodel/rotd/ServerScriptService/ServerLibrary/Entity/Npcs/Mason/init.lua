local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Mason";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        PrimaryGunItemId = "revolver454";
        MeleeItemId = "crowbar";
        Immortal = 1;
        CutsceneActive = false;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "AttractNpcs";
        "ProtectPlayer";
        "FollowPlayer";
        "WaitForPlayer";
    };
    AddBehaviorTrees = {
        "SurvivorIdleTree";
        "SurvivorCombatTree";
    };

    Voice = {
        VoiceId = 3;
        Pitch = -3;
        Speed = 1.4;
        PlaybackSpeed = 0.97;
    };

    SurvivorIdleData = {
        ["Warehouse Safehouse"] = {
            Data = {
                RestTimeInterval = NumberRange.new(70, 120);
                RestPoint = CFrame.lookAt(Vector3.new(28.717, 57.651, 18.246), Vector3.new(15.417, 57.651, 18.246));
                RestDuration = NumberRange.new(19, 29);
                RestSay = {
                    "If anyone needs help, I will be pleased to help out.";
                    "Anyone in need of help?";
                    "I'm just resting for a bit, feel free to come to me if you need anything.";
                    "Taking a breather before getting back to work on that engine.";
                    "Just catching my breath, don't mind me.";
                    "Feel free to ask me about repairs or maintenance.";
                    "I could use a coffee break, but this'll do for now.";
                    "Keeping an eye on things while I rest.";
                }
            };

            warehouseToolCupboard = {
                Chance = 1;
                Say = {
                    "Maybe this tool will work..";
                    "Dagnabbit, where did I put the wrench..";
                    "What on earth is this atom-looking thingamajig??";
                    "...How many times do I have to tell Russell that the wrench is not the sharpest tool in the shed..";
                };
                Duration = NumberRange.new(33, 43);
            };
            warehouseBrokenEngine = {
                Chance = 1;
                Say = {
                    "This engine is completely busted..";
                    "I need to find the right parts to fix this..";
                    "Hmm.. the timing belt is torn, and the pistons are damaged..";
                    "If only I had my repair manual with me..";
                    "*sighs* This is going to take a while to fix.";
                };
                Duration = NumberRange.new(33, 43);
            };
            warehouseSafehouseStorage = {
                Chance = 0.7;
                Say = {
                    "I should probably organize this better..";
                    "I wish I had more storage space..";
                    "Maybe I should ask Russell to build me a bigger storage..";
                    "Where did I put that wrench again..?";
                    "I need to get rid of all these easter eggs..";
                };
                Duration = NumberRange.new(20, 30);
            };
            warehouseWorkbench = {
                Chance = 0.5;
                Say = {
                    "Should I increase the damage or the reload speed?..";
                    "I hope Russell doesn't take my wrench again..";
                    "Ahh dagnabbit, I overtweaked my gun again..";
                };
                Duration = NumberRange.new(34, 40);
            };
            warehouseVendingMachine = {
                Chance = 0.5;
                Say = {
                    "C'mon, give me something good!";
                    "Energy drink! Energy drink! I want that energy drink!";
                    "This vending machine is rigged!";
                    "I swear if this thing eats my money again...";
                    "Last time it gave me a grenade instead of a soda!";
                    "Please don't be another beachball...";
                    "*kicks machine* Work properly this time!";
                };
                InteractSay = {
                    "Another grenade?! Are you kidding me..";
                    "Welp there goes another $500.";
                    "Oh a $ItemId, I could use that.";
                    "$ItemId.. Not what I wanted but whatever...";
                    "A $ItemId? This machine is full of surprises!";
                    "Hey, at least it's not another dud...";
                    "Finally! A $ItemId is exactly what I needed!";
                    "*stares at $ItemId* Well... better than nothing I guess.";
                    "This $ItemId better be worth my money...";
                    "Huh, a $ItemId? That's... interesting.";
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