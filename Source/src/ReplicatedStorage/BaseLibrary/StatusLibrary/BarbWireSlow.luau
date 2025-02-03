local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="BarbWireSlow";
    Icon="rbxassetid://16521233112";
    Name="Barb Wire Slow";
    Description="Slowed to $Amountu/s by barbed wires.";
    Buff=true;
};

function statusPackage:OnApply()
    local npcClass = self.NpcClass;
    if npcClass == nil then return end;

    if npcClass.Movement then
        local barbWs = npcClass.Movement.DefaultWalkSpeed * 0.2;
        npcClass.Movement:SetWalkSpeed(statusPackage.Id, barbWs, 5, 1);

        task.delay(1.1, function()
            if npcClass.IsDead then return end;
            npcClass.Movement:UpdateWalkSpeed();
        end)
    end
end

return modStatusClass.new(statusPackage);