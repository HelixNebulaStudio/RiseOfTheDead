local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local statusPackage = {
    Id = "BarbWireSlow";
    Icon = "rbxassetid://16521233112";
    Name = "Barb Wire Slow";
    Description = "Slowed to $Amountu/s by barbed wires.";
    Buff = false;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local characterClass: CharacterClass =  statusClass.StatusOwner :: CharacterClass;
    local newSpeed = statusClass.Values.NewSpeed or 4;

    if characterClass.ClassName == "NpcClass" then
        local npcClass: NpcClass = characterClass :: NpcClass;
        npcClass.Move:SetMoveSpeed(
            "set", 
            "barbslow", 
            newSpeed, 
            npcClass.Move.MoveSpeedPriority.StatusEffect, statusClass.Duration
        );
    end
end

statusPackage.BindUpdate = statusPackage.BindApply;

return modStatusClass.new(statusPackage);