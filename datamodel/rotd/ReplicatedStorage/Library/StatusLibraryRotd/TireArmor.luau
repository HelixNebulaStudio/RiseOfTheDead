local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="TireArmor";
    Icon="rbxassetid://16745983668";
    Name="Tire Armor";
    Description="Tire Armor Passive";
    Buff=true;
};

function statusPackage.OnTick(statusClass: StatusClassInstance, tickData: TickData)
    if statusClass.Visible == nil then
        statusClass.Visible = false;
    end

	if RunService:IsClient() then return end;
	if tickData.ms1000 ~= true then return end;

    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

	local sync = false;

	local equippedItemId = playerClass.WieldComp.ItemId;

    local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
	local isMeleeEquipped = equippedItemId and (modItemsLibrary:HasTag(equippedItemId, "Melee"))

	if isMeleeEquipped and not statusClass.Visible then
		statusClass.Visible = true;
		sync = true;

	elseif not isMeleeEquipped and statusClass.Visible then
		statusClass.Visible = false;
		sync = true;

	end

	return sync;
end

return modStatusClass.new(statusPackage);