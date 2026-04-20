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

    ItemCustomizations = {
        ["ak47"] = [[{"Plans":{"[All]":"#111111;;;,,,,,;WornMetal;;;;","[Diamonds]":";skindiamonds_v1;;#12eed4,,,,,19;;;;;"},"Layers":{"[Diamonds]":"Stock,Grip"}}]];
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

function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if shared.WorldName == "TheWarehouse" then
        npcClass.Properties.CutsceneEquip = properties.PrimaryGunItemId;
        npcClass.WieldComp:Equip{
            ItemId = properties.PrimaryGunItemId;
            ItemCustomizations = npcClass.NpcPackage.ItemCustomizations;
        };
    end
end

return npcPackage;