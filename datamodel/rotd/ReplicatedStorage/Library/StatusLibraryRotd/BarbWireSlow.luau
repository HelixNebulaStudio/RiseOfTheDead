local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="BarbWireSlow";
    Icon="rbxassetid://16521233112";
    Name="Barb Wire Slow";
    Description="Slowed to $Amountu/s by barbed wires.";
    Buff=true;
};

function statusPackage.OnApply(statusClass: StatusClassInstance)
    local characterClass: CharacterClass =  statusClass.StatusOwner;
end

return modStatusClass.new(statusPackage);