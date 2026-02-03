local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local RunService = game:GetService("RunService");
--==
local statusPackage = {
    Id = "fiaitr";
    Icon = "rbxassetid://4493354290";
    Name = "Skill: First Aid Training";
    Description = "Medkits use speed increased by $Percent%.";
    Buff = true;
    ExpiresOnDeath = true;
};

return modStatusClass.new(statusPackage);