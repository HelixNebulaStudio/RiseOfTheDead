local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Erik";
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
        Pitch = 1.2;
        Speed = 1.05;
        PlaybackSpeed = 1.05;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    -- if self.AnimationController:IsPlaying("Scared") then
    --     self.AnimationController:Play("ScaredPeek", {FadeTime=2});
        
    --     wait(0.5);
    --     self.AnimationController:Stop("Scared", {FadeTime=2});
    -- end
end

return npcPackage;