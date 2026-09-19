local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Bunny Man";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "ProtectPlayer";
        "FollowPlayer";
        "WaitForPlayer";
    };

    Voice = {
        VoiceId = 3;
        Pitch = -5;
        Speed = 1.5;
        PlaybackSpeed = 1.4;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

function npcPackage.Spawned(npcClass: NpcClass)
    local npcChar = npcClass.Character;

    task.spawn(function()
        local modItemUnlockablesLibrary = shared.require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
        local apronAccessories = {
            npcChar:WaitForChild("UT");
            npcChar:WaitForChild("LT");
            npcChar:WaitForChild("LT2");
        };
        for _, accessory in ipairs(apronAccessories) do
            modItemUnlockablesLibrary.UpdateSkin(accessory, "aproncarnage");
        end
    end)
end

return npcPackage;