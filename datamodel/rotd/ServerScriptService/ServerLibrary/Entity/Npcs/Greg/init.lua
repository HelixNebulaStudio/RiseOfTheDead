local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local NpcRoutineData = shared.require(game.ReplicatedStorage.Data.NpcRoutineData);
--==
local npcPackage = {
    Name = "Greg";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        PrimaryGunItemId = "p250";
        MeleeItemId = "fireaxe";
        MeleeRange = 12;
        Immortal = 1;
        CutsceneActive = false;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "AttractNpcs";
        "NpcRoutine";
        "CutscenePlayers";
    };
    AddBehaviorTrees = {
        "SurvivorCombatTree";
    };

    Voice = {
        VoiceId = 7;
        Pitch = -2;
        Speed = 0.7;
        PlaybackSpeed = 0.95;
    };

    RoutineSchedules = {
        NpcRoutineData.new{
            WorldId = "TheHarbor";
            ClockTime = 2;
            Actions = {
                {Run="Sleep"; CFrame=CFrame.new(-346.17, 63.046, 199.54) * CFrame.Angles(0, math.rad(-73), 0);};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheHarbor";
            ClockTime = 9.5;
            Actions = {
                {Run="SetCFrame"; CFrame=CFrame.new(-346.17, 63.046, 199.54) * CFrame.Angles(0, math.rad(-73), 0);};
                {Run="WakeUp";};
            };
        };

        NpcRoutineData.new{
            WorldId = "TheHarbor";
            ClockTime = 10;
            Actions = {
                {CFrame=CFrame.new(-253.988, 62.661, 193.25) * CFrame.Angles(0, math.rad(180), 0);};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheHarbor";
            ClockTime = 11;
            Actions = {
                {CFrame=CFrame.new(-156.865, 62.661, 134.767) * CFrame.Angles(0, math.rad(180), 0);};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheHarbor";
            ClockTime = 12;
            Actions = {
                {Run="Lunch"; CFrame=CFrame.new(-155.852, 63.981, 512.2) * CFrame.Angles(0, math.rad(142.85), 0);};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheHarbor";
            ClockTime = 16;
            Actions = {
                {CFrame=CFrame.new(-25.089, 63.931, 180.881) * CFrame.Angles(0, math.rad(180), 0);};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheHarbor";
            ClockTime = 18;
            Actions = {
                {CFrame=CFrame.new(-112.214, 63.031, 319.365) * CFrame.Angles(0, math.rad(-136), 0);};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheHarbor";
            ClockTime = 20;
            Actions = {
                {CFrame=CFrame.new(-368.598, 63.984, 420.154) * CFrame.Angles(0, math.rad(-14.8), 0);};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheHarbor";
            ClockTime = 22;
            Actions = {
                {CFrame=CFrame.new(-429.786, 63.031, 244.102) * CFrame.Angles(0, math.rad(-90), 0);};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheHarbor";
            ClockTime = 23.5;
            Actions = {
                {Run="InteractWith"; InteractId="RatHqVendingMachine"; CFrame=CFrame.new(-319.445, 63.046, 252.309);};
                {Run="Say"; Say={
                    "Rubbish!";
                    "Trash!";
                    "Junk!";
                    "Garbage!";
                    "Scrap!";
                    "Useless!";
                };};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheHarbor";
            ClockTime = 23.5;
            Actions = {
                {Run="InteractWith"; InteractId="RatHqSafeStorage"; CFrame=CFrame.new(-319.512, 63.046, 234.075) * CFrame.Angles(0, math.rad(180), 0);};
            };
        };

    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local attractNpcsComp = npcClass:GetComponent("AttractNpcs");
    if attractNpcsComp then
        attractNpcsComp.AttractHumanoidType = {"Zombie"; "Bandit"};
        attractNpcsComp.SelfAttractAlert = true;
        attractNpcsComp:Activate();
    end
end

return npcPackage;