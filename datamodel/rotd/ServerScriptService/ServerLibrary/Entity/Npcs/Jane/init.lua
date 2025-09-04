local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Jane";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        PrimaryGunItemId = "p250";
        MeleeItemId = "survivalknife";
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
        VoiceId = 6;
        Pitch = 3;
        Speed = 0.9;
        PlaybackSpeed = 1.1;
    };
    
    SurvivorIdleData = {
        ["Sunday's Safehouse"] = {
            Data = {
                RestTimeInterval = NumberRange.new(90, 160);
                RestingSeatName = "JaneSeat";
                RestDuration = NumberRange.new(20, 29);
                RestSay = {
                    "Nooo~! We've lost the signal again..";
                    "I hope they are alright.";
                    "What are we going to do?!";
                    "Sigh..";
                };
            };

            sundaysSafehouseStorage = {
                Chance = 1;
                Say = {
                    "Let me make sure everything is neatly organized~";
                    "*hums while sorting* A tidy storage makes it easier to find things!";
                    "I should check if we need anything important..";
                    "*carefully arranges items* Everything has its special place!";
                    "I hope everyone can find what they need easily~";
                    "*gently organizing* Taking care of our supplies is so important!";
                };
                Duration = NumberRange.new(20, 30);
            };
            sundaysWorkbench = {
                Chance = 1;
                Say = {
                    "Let's see if I can make something useful for everyone~";
                    "*carefully arranges tools* Everything needs to be just right!";
                    "I hope this turns out well... everyone's counting on me!";
                    "*hums softly* A little care goes a long way with these repairs~";
                    "Oh! Maybe I can make something special for the group today!";
                };
                Duration = NumberRange.new(34, 40);
            };
            sundaysShop = {
                Chance = 0.5;
                Say = {
                    "Hi Frank! I hope you're taking good care of yourself today~";
                    "*smiles warmly* Your shop always has such wonderful things!";
                    "Frank, have you eaten yet? I brought some snacks to share!";
                    "*cheerfully* Let's see what treasures you have for us today!";
                    "You work so hard, Frank! Don't forget to take breaks, okay?";
                    "*gently* Your shop is such a blessing to our community~";
                };
                Duration = NumberRange.new(30, 34);
            };
            sundaysVendingMachine = {
                Chance = 0.5;
                Say = {
                    "Oh, I wonder what goodies are in here today!";
                    "*hums cheerfully* Maybe I'll get something nice for everyone.";
                    "I hope it has those energy drinks the others like so much!";
                    "*gently pats machine* Please be nice to me today~";
                    "A little treat wouldn't hurt, right?";
                };
                InteractSay = {
                    "Aww, a $ItemId! How wonderful~";
                    "*holds $ItemId carefully* I'll make sure to share this with everyone!";
                    "Oh my, a $ItemId! This will definitely come in handy.";
                    "*giggles* The machine was extra nice today, gave me a $ItemId!";
                    "A $ItemId! I knew being nice to the machine would work~";
                    "*smiles warmly* This $ItemId will make someone's day better!";
                };
                InteractTime = -4;
                Duration = NumberRange.new(14, 20);
            };
        };
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;