local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local npcPackage = {
    Name = "Mysterious Engineer";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
    };

    Voice = {
        VoiceId = 3;
        Pitch = -4;
        Speed = 0.95;
        PlaybackSpeed = 0.99;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

function npcPackage.Spawned(npcClass: NpcClass)
    task.delay(1, function()
        local seat = workspace.Environment:FindFirstChild("Game") and workspace.Environment.Game:FindFirstChild("MESeat");
        if seat then
            npcClass:Sit(seat);
        end
    end)
end

return npcPackage;