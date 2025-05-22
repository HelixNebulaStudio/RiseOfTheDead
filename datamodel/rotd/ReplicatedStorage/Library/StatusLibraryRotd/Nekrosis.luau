local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
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
    local playerClass: PlayerClass = self.PlayerClass;
    if playerClass == nil then return end;

	local humanoid = playerClass.Humanoid;
	if self.Visible == nil then 
        self.Visible = false;
    end
	
	local sync = false;
	
	local lastDmgedTime = workspace:GetServerTimeNow()-playerClass.HealthComp.LastDamageTaken;
	if lastDmgedTime < 15 then
		if self.Values.HealRate ~= nil then
			self.Values.HealRate = nil;
			self.Visible = false;
			sync = true;
		end
		
	else
		if self.Values.HealRate == nil and humanoid.Health < humanoid.MaxHealth then
			local cNekrosisHeal = (playerClass.Configurations.NekrosisHeal or 0)/10;

			self.Values.HealRate = cNekrosisHeal;
			
			self.Amount = cNekrosisHeal;
			self.Visible = true;
			sync = true;
			
		elseif self.Visible == true and humanoid.Health >= humanoid.MaxHealth then
			self.Values.HealRate = nil;

			self.Visible = false;
			sync = true;
			
		end
		
	end
	
	return sync;
end

return modStatusClass.new(statusPackage);