local RunService = game:GetService("RunService");
local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
--==
local statusPackage = {
    Id="Nekrosis";
    Icon="rbxassetid://14423236705";
    Name="Nekrosis";
    Description="You are healing from Nekrosis, +$Amount hp/s.";
    DescProcess={
        ["Amount"]=(function(v) return v*10; end);
    };
    Buff=true;
    Cleansable=true;
};

function statusPackage:OnTick()
	if RunService:IsClient() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

	local humanoid = playerClass.Humanoid;
	if self.Visible == nil then 
        self.Visible = false;
    end
	
	local healSources = playerClass.Properties.HealSources;
    
	local sync = false;
	
	local lastDmgedTime = workspace:GetServerTimeNow()-playerClass.LastDamageTaken;
	if lastDmgedTime < 15 then
		if healSources[script.Name] ~= nil then
			healSources[script.Name] = nil;
			self.Visible = false;
			sync = true;
		end
		
	else
		if healSources[script.Name] == nil and humanoid.Health < humanoid.MaxHealth then
			local duration = 5;

			local nekrosHealAmount = (playerClass:GetBodyEquipment("ModNekrosisHeal") or 0)/10;
			local healSrc = {
				Amount=nekrosHealAmount;
				Expires=modSyncTime.GetTime() + duration;
				Duration=duration;
			};
			
			playerClass:SetHealSource(script.Name, healSrc);
			self.Amount = nekrosHealAmount;
			self.Visible = true;
			sync = true;
			
		elseif self.Visible == true and humanoid.Health >= humanoid.MaxHealth then
			self.Visible = false;
			sync = true;
			
		end
		
	end
	
	return sync;
end

return modStatusClass.new(statusPackage);