local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService")

local localPlayer = game.Players.LocalPlayer;

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

--==
local statusPackage = {
    Id="TiedUp";
    Icon="rbxassetid://4983245856";
    Name="Tied Up";
    Description="You are tied up and cannot move or do anything while being tied up.";
    Buff=false;
    Tags = {"Mobility"; "Stun";};
    Cleansable=true;
    ExpiresOnDeath=true;
};
function statusPackage.onRequire()
    ropePrefab = game.ReplicatedStorage.Prefabs.Objects:WaitForChild("TieUpRope");
    tiedUpAnimation = game.ReplicatedStorage.Prefabs.Animations.Generic:WaitForChild("TiedUpStatus");

    if RunService:IsClient() then
        modData = shared.require(localPlayer:WaitForChild("DataModule"));
    end
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil then return end;

    local rootPart = characterClass.RootPart;

    if RunService:IsServer() then
		if rootPart then
            game.Debris:AddItem(characterClass.Character:FindFirstChild("TieUpRope") , 0);

            local newRope = ropePrefab:Clone();
			local joint = newRope:WaitForChild("Weld");
			newRope.Parent = characterClass.Character;
			joint.Part0 = newRope;
			joint.Part1 = rootPart;
            statusClass.Garbage:Tag(newRope);
		end

        if characterClass.ClassName == "NpcClass" then
            local npcClass: NpcClass = characterClass :: NpcClass;

            npcClass.Move:SetMoveSpeed("set", statusPackage.Id, 0, npcClass.Move.MoveSpeedPriority.StatusEffect);

            npcClass.PlayAnimation(tiedUpAnimation.Name);
        end

    elseif RunService:IsClient() then

		local animator = characterClass.Humanoid:WaitForChild("Animator");
		local track: AnimationTrack = animator:LoadAnimation(tiedUpAnimation);
		track:Play(0.25);
        statusClass.Values.AnimationTrack = track;

		local modCharacter = modData:GetModCharacter();
		modCharacter.CharacterProperties.CanMove = false;
		modCharacter.CharacterProperties.CanAction = false;
		modCharacter.MouseProperties.Mouse1Down = false;
		modCharacter.MouseProperties.Mouse2Down = false;
		modCharacter.UpdateWalkSpeed();
    end
    
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil then return end;
    
    if RunService:IsServer() then
        if characterClass.ClassName == "NpcClass" then
            local npcClass: NpcClass = characterClass :: NpcClass;

            npcClass.Move:SetMoveSpeed("remove", statusPackage.Id);

            npcClass.StopAnimation(tiedUpAnimation.Name);
        end

    else
        
        local track = statusClass.Values.AnimationTrack;
        if track then
            track:Stop(0.25);
        end
        
		local modCharacter = modData:GetModCharacter();
        modCharacter.CharacterProperties.CanMove = true;
        modCharacter.CharacterProperties.CanAction = true;
        modCharacter.UpdateWalkSpeed();

    end
end

return modStatusClass.new(statusPackage);