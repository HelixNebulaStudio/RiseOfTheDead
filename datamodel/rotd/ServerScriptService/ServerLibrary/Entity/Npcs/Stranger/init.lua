local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Stranger";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    AddComponents = {
        "TargetHandler";
        "Chat";
        "RandomClothing";
        "AttractNpcs";
        "ProtectPlayer";
        "FollowPlayer";
        "WaitForPlayer";
    };

    Voice = {
        VoiceId = NumberRange.new(1, 7);
        Pitch = NumberRange.new(-3, 2);
        Speed = NumberRange.new(0.98, 1.02);
        PlaybackSpeed = NumberRange.new(0.98, 1.02);
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if properties.Seed == nil then 
        properties.Seed = math.random(1, 100000);
    end;

    npcClass:GetComponent("RandomClothing"){
        Name = "Stranger";
    };
end

return npcPackage;