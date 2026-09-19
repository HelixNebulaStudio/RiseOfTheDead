local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id = "InfSlide";
    Icon = "rbxassetid://10368377851";
    Name = "InfSlide";
    Description = "Infinite Slide";
    Buff = true;
    ExpiresOnDeath = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    local characterComp = playerClass.CharacterComp;
    characterComp.DefaultFlatFriction = 0;
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    local characterComp = playerClass.CharacterComp;
    characterComp.DefaultFlatFriction = 0.9;
end


return modStatusClass.new(statusPackage);