local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="agirec";
    Icon="rbxassetid://4561097552";
    Name="Skill: Agile Recovery";
    Description="Movement impairment debuff duration reduced by $Percent%.";
    Buff=true;
};

return modStatusClass.new(statusPackage);