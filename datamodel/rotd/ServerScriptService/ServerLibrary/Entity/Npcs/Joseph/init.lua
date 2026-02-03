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
        -- NpcRoutineData.new{
        --     WorldId = "TheHarbor";
        --     ClockTime = 2;
        --     Actions = {
        --         {Run="Sleep"; CFrame=CFrame.new(-365.327, 63.046, 202.4) * CFrame.Angles(0, math.rad(167), 0);};
        --     };
        -- };
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