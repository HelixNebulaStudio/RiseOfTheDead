local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Patrick";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        PrimaryGunItemId = "ak47";
        MeleeItemId = "shovel";
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "FollowPlayer";
        "ProtectPlayer";
        "AttractNpcs";
    };
    AddBehaviorTrees = {
        "SurvivorCombatTree";
    };

    Voice = {
        VoiceId = 3;
        Pitch = -2;
        Speed = 1;
        PlaybackSpeed = 1.01;
    };

    ItemCustomizations = {
        ["ak47"] = [[{"Plans":{"[Third]":"#965555;;;,,,,,;WornMetal;;;;","[Primary]":"#1b2a35;;0;,,,,,;OldMetal;0;;;","Magazine":";;;,,,,,;;;-50,210,0;87,66,98;","[All]":";;;,,,,,;;;;;","[Secondary]":"#965555;skindeathcamo_v1;0;,,,,,25;RustySpots;0;;;"},"Layers":{"[Third]":"Safety,ChargingHandle"}}]];
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
    if shared.WorldName == "TheMall" then
        npcClass.Properties.CutsceneEquip = properties.PrimaryGunItemId;
        npcClass.WieldComp:Equip{
            ItemId = properties.PrimaryGunItemId;
            ItemCustomizations = npcClass.NpcPackage.ItemCustomizations;
        };
        npcClass.Move:SetMoveSpeed("set", "post", 0, 11);
    end
end

return npcPackage;