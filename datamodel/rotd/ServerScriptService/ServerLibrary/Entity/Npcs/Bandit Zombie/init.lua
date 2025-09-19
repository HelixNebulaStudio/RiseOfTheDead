local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Bandit Zombie";
    HumanoidType = "Zombie";
    
	Configurations = {};
    Properties = {
        BasicEnemy = false;
        Level = 1;
    };

    AddComponents = {
        "TargetHandler";
        "Chat";
    };

    Voice = {
        VoiceId = 3;
        Pitch = 0.6;
        Speed = 1.8;
        PlaybackSpeed = 0.6;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;