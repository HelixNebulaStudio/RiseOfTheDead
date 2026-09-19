local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local NpcRoutineData = shared.require(game.ReplicatedStorage.Data.NpcRoutineData);

local npcPackage = {
    Name = "Joseph";
    HumanoidType = "Human";
    
	Configurations = {
        WalkSpeed = 18;
    };
    Properties = {
        PrimaryGunItemId = "revolver454";
        MeleeItemId = "pickaxe";
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "AttractNpcs";
        "ProtectPlayer";
        "FollowPlayer";
        "WaitForPlayer";
        "NpcRoutine"
    };
    AddBehaviorTrees = {
        "SurvivorCombatTree";
        "CutsceneTree";
    };

    Voice = {
        VoiceId = 7;
        Pitch = 0.95;
        Speed = 0.95;
        PlaybackSpeed = 0.95;
    };
    
    RoutineSchedules = {
        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 2;
            Actions = {
                {Run="Sleep"; CFrame=CFrame.new(1303.971, 62.681, 71.457) * CFrame.Angles(0, math.rad(90), 0);};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 9.5;
            Actions = {
                {Run="SetCFrame"; CFrame=CFrame.new(1303.971, 62.681, 71.457) * CFrame.Angles(0, math.rad(90), 0);};
                {Run="WakeUp";};
            };
        };

        
        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 10;
            Actions = {
                {CFrame=CFrame.new(1225.898, 57.81, -69.65) * CFrame.Angles(0, math.rad(90), 0);};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 12.5;
            Actions = {
                {CFrame=CFrame.new(1287.713, 56.81, -56.132) * CFrame.Angles(0, math.rad(90), 0);};
                {Run="Emote"; Ids={"LeanOverInspect"}};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 15.5;
            Actions = {
                {CFrame=CFrame.new(1271.89, 57.839, -72.163) * CFrame.Angles(0, math.rad(-90), 0);};
                {Run="Emote"; Ids={"LeanOverInspect"}};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 18.5;
            Actions = {
                {CFrame=CFrame.new(1255.481, 57.839, -49.549) * CFrame.Angles(0, math.rad(0), 0);};
                {Run="Emote"; Ids={"LeanOverInspect"}};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 20.5;
            Actions = {
                {CFrame=CFrame.new(1246.618, 57.839, -74.98) * CFrame.Angles(0, math.rad(90), 0);};
                {Run="Emote"; Ids={"LeanOverInspect"}};
            };
        };

        
        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 23.5;
            Actions = {
                {CFrame=CFrame.new(1225.898, 57.81, -69.65) * CFrame.Angles(0, math.rad(90), 0);};
            };
        };
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local attractNpcsComp = npcClass:GetComponent("AttractNpcs");
    if attractNpcsComp then
        attractNpcsComp.AttractHumanoidType = {"Zombie";};
        attractNpcsComp.SelfAttractAlert = true;
        attractNpcsComp:Activate();
    end
end

return npcPackage;