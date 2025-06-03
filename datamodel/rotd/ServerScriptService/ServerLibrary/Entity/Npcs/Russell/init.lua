local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Russell";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {};

    DialogueInteractable = true;

    Chatter = {
        Greetings = {
            "Looking to fix up your weapons?";
        };
    };

    AddComponents = {
        "TargetHandler";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    npcClass.Garbage:Tag(npcClass.OnThink:Connect(function()
        npcClass.BehaviorTree:RunTree(script.RussellDefaultTree, true);
    end)); 
end

function npcPackage.Spawned(npcClass: NpcClass)
    local russellSeat = workspace.Environment:FindFirstChild("RussellSeat");
    Debugger:Warn(`russellSeat exist`, russellSeat);

end

return npcPackage;