local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local StatusClass = require(script.Parent.StatusClass).new();
--==
local key = string.lower(script.Name);

if RunService:IsServer() then
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

	modOnGameEvents:ConnectEvent("OnNpcDamaged", function(player, damageSource)
		local classPlayer = shared.modPlayers.Get(player);
		if classPlayer == nil then return end;

		if classPlayer.Properties.WarmongerScales == nil then return end;
		if classPlayer.Properties.PacifistsAmulet then return; end -- disable if pacifists present;

		local status = classPlayer.Properties.WarmongerScales;

		local damage = damageSource.Damage;
		local npcModule = damageSource.NpcModule;
		local maxHealth = npcModule.Humanoid.MaxHealth;

		local humanoid = classPlayer.Humanoid;

		local ratio = math.clamp(damage/maxHealth, 0.1, 1);
		local add = ratio * status.HealthPerKill;
		
		local oldPool = (status.Pool or 0);
		status.Pool = math.clamp(oldPool + add, 0, status.Max);
		status.LastDeduct = tick()+1;
		
		if status.Pool > oldPool then
			local dif = status.Pool-oldPool;
			
			status.Buffer = (status.Buffer or 0) + dif;
		end
		
		classPlayer:SyncProperty("WarmongerScales");
	end)
	
end

function StatusClass.OnTick(classPlayer, status, tickPack)
	if RunService:IsServer() then
		if tickPack.ms100 ~= true then return end;

		local timeSinceDoingDmg = tick()-classPlayer.LastDamageDealt;
		
		if timeSinceDoingDmg >= 10 and (status.Pool and status.Pool > 0) then
			status.Pool = math.max(status.Pool - 0.1, 0);
		end
		if status.Buffer and status.Buffer > 0 and classPlayer.Humanoid.Health < classPlayer.Humanoid.MaxHealth then
			classPlayer.Humanoid.Health = classPlayer.Humanoid.Health +status.Buffer;
			status.Buffer = 0;
		end
		
		local hoSrcs = classPlayer.Properties.HealthOverchargeSources;
		hoSrcs[key] = status.Pool;
		
		return true;
	else
		
	end;
end

function StatusClass.OnExpire(classPlayer, status)
	if RunService:IsServer() then
		local hoSrcs = classPlayer.Properties.HealthOverchargeSources;
		hoSrcs[key] = nil;

	end;

end

return StatusClass;