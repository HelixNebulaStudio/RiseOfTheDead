local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Nekrosis";
    Icon="rbxassetid://14423236705";
    Name="Nekrosis";
    Description="You are healing from Nekrosis, +$Amount hp/s.";
    Buff=true;
    Cleansable=true;
};

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
	if RunService:IsClient() then return end;
	if tickData.ms100 == false then return end;

	local sync = false;
	
	local characterClass: CharacterClass = statusClass.StatusOwner;
	local healthComp: HealthComp? = characterClass.HealthComp;
	if healthComp == nil then return end;

	local lastDmgedTime = workspace:GetServerTimeNow() - healthComp.LastDamageTaken;
	local ratio = math.clamp(lastDmgedTime/15, 0, 1);

	local cNekrosisHeal = characterClass.Configurations.NekrosisHeal or 0;
	if cNekrosisHeal <= 0 then
		statusClass.IsExpired = true;
		return;
	end

	statusClass.Values.Amount = characterClass.Configurations.NekrosisHeal; -- desc

	if ratio < 1 then
		sync = statusClass.Alpha ~= ratio;
		statusClass.Alpha = ratio;
		statusClass.Values.HealRate = nil;

	else
		if statusClass.Values.HealRate == nil and healthComp.CurHealth < healthComp.MaxHealth then
			local nekroHealRate = cNekrosisHeal/10;

			statusClass.Values.HealRate = nekroHealRate;
			statusClass.Alpha = 1;

			sync = true;

		elseif healthComp.CurHealth >= healthComp.MaxHealth then
			statusClass.IsExpired = true;

		end
	end

	if sync then
		statusClass:Sync();
	end
end

return modStatusClass.new(statusPackage);