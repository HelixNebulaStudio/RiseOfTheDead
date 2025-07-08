local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="Freezing";
    Icon="rbxassetid://10371553364";
    Name="Freezing";
    Description="You are freezing, you will lose mobility and won't be able to perform actions.";
    Buff=false;
    Tags = {"Mobility"; "Slow";};
    Cleansable=true;
    ExpiresOnDeath=true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    local playerClass: PlayerClass = statusClass.StatusOwner :: PlayerClass;
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local modCharacter = modData:GetModCharacter();

    modCharacter.CharacterProperties.WalkSpeed:Set("freezing", 10, 4);
    modCharacter.UpdateWalkSpeed();

    task.spawn(function()
        if playerClass.Properties["FreezingWs"] then return end;
        playerClass.Properties["FreezingWs"] = true;
        modCharacter.CharacterProperties.CanSprint = false;
        modCharacter.CharacterProperties.CanAction = false;

        local modEmotes = shared.require(game.ReplicatedStorage.Library.EmotesLibrary);
        local animLib = modEmotes:Find("feelingcold");
        if animLib then
            local animator = playerClass.Humanoid:WaitForChild("Animator");
            local track = animator:LoadAnimation(animLib.Animation);
            track:Play();
        end;

        local disarmTick = tick();
        repeat
            task.wait();

            if tick()-disarmTick >= 1.3 then
                modCharacter.CharacterProperties.CanAction = true;
            end
        until playerClass.Properties.Freezing == nil;

        modCharacter.CharacterProperties.CanSprint = true;
        modCharacter.CharacterProperties.CanAction = true;
        if modCharacter then
            modCharacter.CharacterProperties.WalkSpeed:Remove("freezing");
        end
        playerClass.Properties["FreezingWs"] = nil;
    end)
end

return modStatusClass.new(statusPackage);