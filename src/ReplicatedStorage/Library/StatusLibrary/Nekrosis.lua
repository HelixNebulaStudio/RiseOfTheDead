local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local StatusClass = require(script.Parent.StatusClass).new();
--==

local statusVisibility = false;
function StatusClass.OnTick(classPlayer, status)
	if RunService:IsClient() then return end;
	
	local humanoid = classPlayer.Humanoid;
	if status.Visible == nil then status.Visible = statusVisibility; end
	
	local properties = classPlayer.Properties;
	local bodyEquipments = properties.BodyEquipments;
	local sync = false;
	
	local lastDmgedTime = tick()-classPlayer.LastDamageTaken;
	if lastDmgedTime < 15 then
		if properties.HealSources[script.Name] ~= nil then
			properties.HealSources[script.Name] = nil;
			status.Visible = statusVisibility;
			sync = true;
		end
		
	else
		if properties.HealSources[script.Name] == nil and humanoid.Health < humanoid.MaxHealth then
			local duration = 5;
			local healSrc = {
				Amount=classPlayer:GetBodyEquipment("ModNekrosisHeal");
				Expires=modSyncTime.GetTime() + duration;
				Duration=duration;
			};
			
			classPlayer:SetHealSource(script.Name, healSrc);
			status.Amount = healSrc.Amount;
			status.Visible = true;
			sync = true;
			
		elseif status.Visible == true and humanoid.Health >= humanoid.MaxHealth then
			status.Visible = statusVisibility;
			sync = true;
			
		end
		
	end
	
	return sync;
end

return StatusClass;
