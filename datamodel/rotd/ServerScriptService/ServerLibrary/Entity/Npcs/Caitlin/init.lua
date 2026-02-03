local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Caitlin";
    HumanoidType = "Human";
    
	Configurations = {
        WalkSpeed = 19;
    };
    Properties = {
        PrimaryGunItemId = "mp7";
        MeleeItemId = "survivalknife";
        MeleeRange = 8;
        Immortal = 1;
        CutsceneActive = false;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "AttractNpcs";
        "FollowPlayer";
        "WaitForPlayer";
    };
    AddBehaviorTrees = {
        "SurvivorCombatTree";
        "CutsceneTree";
    };

    Voice = {
        VoiceId = 8;
        Pitch = -1;
        Speed = 1;
        PlaybackSpeed = 1.05;
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