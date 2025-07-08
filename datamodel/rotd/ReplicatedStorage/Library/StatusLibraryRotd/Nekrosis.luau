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

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
	if RunService:IsClient() then return end;

    local playerClass: PlayerClass = statusClass.StatusOwner;
    if playerClass == nil or playerClass.ClassName ~= "PlayerClass" then return end;

	local humanoid = playerClass.Humanoid;
	if statusClass.Visible == nil then 
        statusClass.Visible = false;
    end
	
	local sync = false;
	
	local lastDmgedTime = workspace:GetServerTimeNow()-playerClass.HealthComp.LastDamageTaken;
	if lastDmgedTime < 15 then
		if statusClass.Values.HealRate ~= nil then
			statusClass.Values.HealRate = nil;
			statusClass.Visible = false;
			sync = true;
		end
		
	else
		if statusClass.Values.HealRate == nil and humanoid.Health < humanoid.MaxHealth then
			local cNekrosisHeal = (playerClass.Configurations.NekrosisHeal or 0)/10;

			statusClass.Values.HealRate = cNekrosisHeal;
			
			statusClass.Amount = cNekrosisHeal;
			statusClass.Visible = true;
			sync = true;
			
		elseif statusClass.Visible == true and humanoid.Health >= humanoid.MaxHealth then
			statusClass.Values.HealRate = nil;

			statusClass.Visible = false;
			sync = true;
			
		end
		
	end
	
	return sync;
end

return modStatusClass.new(statusPackage);