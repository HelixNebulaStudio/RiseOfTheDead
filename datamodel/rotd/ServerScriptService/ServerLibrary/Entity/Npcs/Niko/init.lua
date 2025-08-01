local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Niko";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    Chatter = {
        Greetings = {
            "Looking to fix up your weapons?";
        };
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;