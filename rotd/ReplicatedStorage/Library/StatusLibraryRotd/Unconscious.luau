local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService")

local localPlayer = game.Players.LocalPlayer;

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

--==
local statusPackage = {
    Id = "Unconscious";
    Icon = "rbxassetid://4644356184";
    Name = "Unconscious";
    Description = "You are unconscious";
    Buff = false;
    Tags = {"Mobility"; "Stun";};
    Cleansable = false;
    ExpiresOnDeath = true;
};

function statusPackage.onRequire()
    unconsciousAnimation = game.ReplicatedStorage.Prefabs.Animations.Generic:WaitForChild("UnconsciousStatus");

    if RunService:IsClient() then
        modData = shared.require(localPlayer:WaitForChild("DataModule"));
    end
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass == nil then return end;

    local rootPart = characterClass.RootPart;

    if RunService:IsServer() then
        if characterClass.ClassName == "NpcClass" then
            local npcClass: NpcClass = characterClass :: NpcClass;

            npcClass.Move:SetMoveSpeed("set", statusPackage.Id, 0, npcClass.Move.MoveSpeedPriority.StatusEffect);

            npcClass.PlayAnimation(unconsciousAnimation.Name);
        end

    elseif RunService:IsClient() then

		local animator = characterClass.Humanoid:WaitForChild("Animator");
		local track: AnimationTrack = animator:LoadAnimation(unconsciousAnimation);
		track:Play(0.25);
        statusClass.Values.AnimationTrack = track;

		local modCharacter = modData:GetModCharacter();
		modCharacter.CharacterProperties.CanMove = false;
		modCharacter.CharacterProperties.CanTurn = false;
		modCharacter.CharacterProperties.CanAction = false;
		modCharacter.MouseProperties.Mouse1Down = false;
		modCharacter.MouseProperties.Mouse2Down = false;
		modCharacter.UpdateWalkSpeed();
    end
    
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass == nil then return end;
    
    if RunService:IsServer() then
        if characterClass.ClassName == "NpcClass" then
            local npcClass: NpcClass = characterClass :: NpcClass;

            npcClass.Move:SetMoveSpeed("remove", statusPackage.Id);

            npcClass.StopAnimation(unconsciousAnimation.Name);
        end

    else
        
        local track = statusClass.Values.AnimationTrack;
        if track then
            track:Stop(0.25);
        end
        
		local modCharacter = modData:GetModCharacter();
        modCharacter.CharacterProperties.CanMove = true;
		modCharacter.CharacterProperties.CanTurn = true;
        modCharacter.CharacterProperties.CanAction = true;
        modCharacter.UpdateWalkSpeed();

    end
end

return modStatusClass.new(statusPackage);