local RunService = game:GetService("RunService");
local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="TireArmor";
    Icon="rbxassetid://16745983668";
    Name="Tire Armor";
    Description="Tire Armor Passive";
    Buff=true;
};

function statusPackage:OnTick(tickPack)
    if self.Visible == nil then 
        self.Visible = false; 
    end
	
	if RunService:IsClient() then return end;
	if tickPack.ms1000 ~= true then return end;

    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;
	
	local sync = false;
	
	local equippedTools = playerClass:GetEquippedTools();
	local itemId = equippedTools and equippedTools.ItemId;
    
    local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
	local isMeleeEquipped = itemId and (modItemsLibrary:HasTag(itemId, "Melee"))
	
	if isMeleeEquipped and not self.Visible then
		self.Visible = true;
		sync = true;
		
	elseif not isMeleeEquipped and self.Visible then
		self.Visible = false;
		sync = true;
		
	end
	
	return sync;
end

return modStatusClass.new(statusPackage);