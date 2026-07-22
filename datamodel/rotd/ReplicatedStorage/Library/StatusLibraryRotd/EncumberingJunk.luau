local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id = "EmcumberingJunk";
    Icon = "rbxassetid://70592564332420";
    Name = "Emcumbering Junk";
    Description = "Junk is slowing you by $Amount% walk speed.";
    QuantityLabel = "$Amount%";
    Buff = false;
    Tags = {"Mobility"; "Slow";};
    Cleansable = true;
    ExpiresOnDeath = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;
    statusPackage.BindUpdate(statusClass);
end

function statusPackage.BindUpdate(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    local modCharacter = (characterClass :: PlayerClass).CharacterVars;

    local slowPercent = statusClass.Values.Amount or 5;
    local newWsMulti = math.clamp(100-math.min(slowPercent, 100), 0, 100)/100;

    Debugger:StudioWarn(`newWsMulti`, newWsMulti);
    modCharacter.CharacterProperties.SpeedMulti:Set("junkslows", newWsMulti, 4);
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    modCharacter.CharacterProperties.SpeedMulti:Remove("junkslows");
end

return modStatusClass.new(statusPackage);