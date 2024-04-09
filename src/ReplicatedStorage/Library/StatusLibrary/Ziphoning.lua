local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local StatusClass = require(script.Parent.StatusClass).new();
local localPlayer = game.Players.LocalPlayer;

local modStatusLibrary = require(game.ReplicatedStorage.Library.StatusLibrary);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local RunService = game:GetService("RunService");
--==
if RunService:IsServer() then
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	modOnGameEvents:ConnectEvent("OnNpcDamaged", function(player, damageSource)
		local classPlayer = shared.modPlayers.Get(player);
		
		if classPlayer == nil or classPlayer.Properties.Ziphoning == nil then return end;
		
		local status = classPlayer.Properties.Ziphoning;
		
		local damage = damageSource.Damage;
		local npcModule = damageSource.NpcModule;
		local maxHealth = npcModule.Humanoid.MaxHealth;
		
		local humanoid = classPlayer.Humanoid;
		
		local ratio = math.clamp(damage/maxHealth, 0.1, 1);
		status.Pool = math.clamp(math.round(status.Pool + ratio*5), 0, humanoid.MaxHealth);
		
		classPlayer:SyncProperty("Ziphoning");
	end)
	
	function StatusClass.OnApply(classPlayer, _)
		for k, status in pairs(classPlayer.Properties) do
			local lib = modStatusLibrary:Find(k);
			if lib == nil or lib.Buff == true then continue end
			if lib.Cleansable ~= true then continue end;
			
			status.Expires = modSyncTime.GetTime();
			classPlayer:SyncProperty(k);
		end
	end
	
	function StatusClass.OnTick(classPlayer, status, tickPack)
		if tickPack.ms1000 ~= true then return end;
		
		local humanoid = classPlayer.Humanoid;
		
		local hpPerTick = 1;
		
		local ampMulti = classPlayer:GetBodyEquipment("NekrosisAmpMulti") or 0;
		hpPerTick = hpPerTick + (hpPerTick * ampMulti);
		status.Amount = hpPerTick;
		
		if status.Pool >= hpPerTick then
			status.Pool = math.clamp(math.round(status.Pool - hpPerTick), 0, humanoid.MaxHealth);
			
			classPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
				Damage=hpPerTick;
				TargetPart=classPlayer.RootPart;
				DamageType="Heal";
			})

			return true; -- sync;
		end
	end
	
end


return StatusClass;
