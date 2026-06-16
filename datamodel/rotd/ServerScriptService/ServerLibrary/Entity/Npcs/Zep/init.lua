local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local NpcRoutineData = shared.require(game.ReplicatedStorage.Data.NpcRoutineData);

local npcPackage = {
    Name = "Zep";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
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
                {Run="Sleep"; CFrame=CFrame.new(1185.991, 77.543, 49.462) * CFrame.Angles(0, math.rad(180), 0);};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 9.5;
            Actions = {
                {Run="SetCFrame"; CFrame=CFrame.new(1185.991, 77.543, 49.462) * CFrame.Angles(0, math.rad(180), 0);};
                {Run="WakeUp";};
                {CFrame=CFrame.new(1185.368, 75.34, 73.607) * CFrame.Angles(0, math.rad(90), 0);};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 9.55;
            Actions = {
                {CFrame=CFrame.new(1185.368, 75.34, 73.607) * CFrame.Angles(0, math.rad(90), 0);};
                {Run="Emote"; Ids={"LeanOverInspect"}};
            };
        };
        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 10;
            Actions = {
                {Run="InteractWith"; InteractId="ResidentialHouse2Exit"; CFrame=CFrame.new(1183.697, 60.8, 47.26) * CFrame.Angles(0, math.rad(90), 0);};
                {CFrame=CFrame.new(1222.84, 57.916, -8.644) * CFrame.Angles(0, math.rad(0), 0);};
            };
        };

        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 18;
            Actions = {
                {Run="InteractWith"; InteractId="ResidentialHouse2Entrance"; CFrame=CFrame.new(1178.248, 60.65, 47.307) * CFrame.Angles(0, math.rad(-90), 0);};
                {Run="InteractWith"; InteractId="ResidentialHouse2SofaL"; CFrame=CFrame.new(1147.655, 60.8, 52.29) * CFrame.Angles(0, math.rad(0), 0);};
                {Run="Say"; Say={
                    "Oh right.. Nothing's broadcasting..";
                };};
            };
        };

        NpcRoutineData.new{
            WorldId = "TheResidentials";
            ClockTime = 23.5;
            Actions = {
                {CFrame=CFrame.new(1185.991, 77.543, 49.462) * CFrame.Angles(0, math.rad(0), 0);};
            };
        };
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;