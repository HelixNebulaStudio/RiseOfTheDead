local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Jesse";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        IsInsideShop = true;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "CutscenePlayers";
    };

    Voice = {
        VoiceId = 1;
        Pitch = -1.01;
        Speed = 0.99;
        PlaybackSpeed = 0.99;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local properties = npcClass.Properties;
    
    npcClass.Move:SetMoveSpeed("set", "default", 5);

    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    local cutscenePlayers = npcClass:GetComponent("CutscenePlayers");
    
    targetHandlerComp.OnTargetUpdate:Connect(function()
        task.wait();

        local targetData = targetHandlerComp:MatchFirstTarget(function(targetData)
            if targetData.HealthComp == nil then return end;
            if targetData.HealthComp.IsDead then return end;

            local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;
            if targetCharacterClass.ClassName ~= "PlayerClass" then return false; end;
            
            local player = (targetCharacterClass :: PlayerClass):GetInstance();
            local isInCutscene = cutscenePlayers:GetPlayer(player) ~= nil;
            if not isInCutscene then return false; end;

            return true;
        end);

        if targetData == nil then return end;
        local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;

        if targetData.LastWavedAt == nil or tick() > targetData.LastWavedAt then
            targetData.LastWavedAt = tick() + math.random(5, 15);
            if not properties.IsInsideShop then
                npcClass.PlayAnimation("Wave");
            end
        end

        npcClass.Move:Face(targetCharacterClass:GetCFrame().Position);
    end)
end

return npcPackage;