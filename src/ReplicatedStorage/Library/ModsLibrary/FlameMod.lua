local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};

local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");

local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local fireParticle = game.ReplicatedStorage.Particles.Fire2;

function Mod.Activate(packet)
	local info = modModsLibrary.Get(packet.ItemId);
	local modStorageItem = packet.ModStorageItem;
	local module = packet.WeaponModule;
	
	local dLayerInfo = modModsLibrary.GetLayer("D", packet);
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end
	
	local tLayerInfo = modModsLibrary.GetLayer("T", packet);
	local tValue, tTweakVal = tLayerInfo.Value, tLayerInfo.TweakValue;
	
	if tTweakVal then
		tValue = tValue + tTweakVal;
	end
	
	module.Configurations.Element = info.Element;
	module.Configurations.PropertiesOfMod = {
		Damage = dValue;
		Duration = tValue;
	}

	module:SetPrimaryModHook({
		StorageItemID=modStorageItem.ID; 
		Activate=Mod.ActivateMod;
	}, info);
	
	--toolModule.Configurations.Element = info.Element;
	--toolModule.Configurations.PropertiesOfMod = {
	--	Damage = damage;
	--	Duration = duration;
	--}

	--toolModule:SetPrimaryModHook({
	--	StorageItemID=modStorageItem.ID; 
	--	Activate=Mod.ActivateMod;
	--}, info);
	
	
	--local modStorageItem, toolModule = paramPacket.ModStorageItem, paramPacket.WeaponModule;

	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;

	--local damage = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["D"], info.Upgrades[1].MaxLevel);
	--local duration = ModsLibrary.Linear(info.Upgrades[2].BaseValue, info.Upgrades[2].MaxValue, values["T"], info.Upgrades[2].MaxLevel);

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local bonusDmg = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	damage = damage + bonusDmg;
	--end
	--if paramPacket.TweakStat and info.Upgrades[2].TweakBonus then
	--	local bonusDuration = info.Upgrades[2].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	duration = duration + bonusDuration;
	--end
	
	--toolModule.Configurations.Element = info.Element;
	--toolModule.Configurations.PropertiesOfMod = {
	--	Damage = damage;
	--	Duration = duration;
	--}

	--toolModule:SetPrimaryModHook({
	--	StorageItemID=modStorageItem.ID; 
	--	Activate=Mod.ActivateMod;
	--}, info);
end

if RunService:IsServer() then
	function Mod.ActivateMod(damageSource)
		local player = damageSource.Dealer;
		local weaponItem, weaponModel, toolModule = damageSource.ToolStorageItem, damageSource.ToolModel, damageSource.ToolModule;
		local targetModel, targetPart = damageSource.TargetModel, damageSource.TargetPart;

		local propertiesOfMod = toolModule.Configurations.PropertiesOfMod;

		damageSource.DamageType="FireDamage";
		
		local damagable = modDamagable.NewDamagable(targetModel);

		if damagable and damagable:CanDamage(player) then
			if damagable.Object.ClassName == "NpcStatus" then
				local npcStatus = damagable.Object;
				
				local npcModule = npcStatus:GetModule();
				local entityStatus = npcModule.EntityStatus;
				
				local stacks = entityStatus:GetOrDefault(script.Name);
				if stacks == nil then
					stacks = 0;
					
					entityStatus:Apply(script.Name, stacks);
					
					task.spawn(function()
						task.wait(0.5)
						local new = fireParticle:Clone();
						new.Name = "FlameModFire";
						new.Parent = targetPart;
						Debugger.Expire(new, propertiesOfMod.Duration);
						local start = tick();

						pcall(function() 
							repeat
								stacks = npcModule.EntityStatus:GetOrDefault(script.Name);
								local stackedDamage = propertiesOfMod.Damage + propertiesOfMod.Damage*(stacks or 0);
								
								local currentHealth = npcModule:GetHealth("Health", targetPart);
								local currentHpDmg = currentHealth * 0.01;
								
								if propertiesOfMod.UseCurrentHpDmg ~= false then
									stackedDamage = stackedDamage + currentHpDmg;
								end
								
								if stackedDamage <= 0 then
									return;
								end
								
								damageSource.Damage = stackedDamage;
								damagable:TakeDamagePackage(damageSource);

								modAudio.Play("BurnTick"..math.random(1, 3), targetPart).PlaybackSpeed = math.random(90,110)/100;
								task.wait(0.5);
								
								if not npcModule.Prefab:IsAncestorOf(targetPart) then
									break;
								end
							until npcModule.Humanoid.Health <= 0 or tick()-start >= propertiesOfMod.Duration;

							entityStatus:Apply(script.Name);
						end)
					end)
				else
					entityStatus:Apply(script.Name, stacks+1);
					
				end

			elseif damagable.Object.ClassName == "Destructible" then
				local destructibleObj = damagable.Object;
				
				if targetPart and targetPart:FindFirstChild("FlameModFire") == nil then
					
					damageSource.Damage = propertiesOfMod.Damage;
					damagable:TakeDamagePackage(damageSource);

					local new = fireParticle:Clone();
					new.Name = "FlameModFire";
					new.Parent = targetPart;
					Debugger.Expire(new, propertiesOfMod.Duration);
				end
				
				if CollectionService:HasTag(targetPart, "Flammable") then
					local modFlammable = Debugger:Require(game.ServerScriptService.ServerLibrary.Flammable);
					modFlammable:Ignite(targetPart);
				end
			end
		end

	end;
	
else
	
end

return Mod;