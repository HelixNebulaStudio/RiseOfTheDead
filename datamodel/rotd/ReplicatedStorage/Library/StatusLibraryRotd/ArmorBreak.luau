local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
--==
local statusPackage = {
    Id="ArmorBreak";
    Icon="rbxassetid://6561711943";
    Name="Armor Break";
    Description="Your armor broke after you took $Damage damage. Armor regeneration is delay by $Duration seconds.";
    Buff=false;
    Tags = {"Weaken";};
    Cleansable=true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil then return end;

    if characterClass.RootPart then
        modAudio.Play("ArmorBreak", characterClass.RootPart).PlaybackSpeed = math.random(90, 110)/100;
    end
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil then return end;

    characterClass.Properties.ArmorRegenDelay = 1;
end

return modStatusClass.new(statusPackage);