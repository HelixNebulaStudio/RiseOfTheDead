local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Michael";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        PrimaryGunItemId = "ak47";
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
        "SurvivorCombatTree";
    };

    Voice = {
        VoiceId = 7;
        Pitch = -4;
        Speed = 1.2;
        PlaybackSpeed = 0.9;
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