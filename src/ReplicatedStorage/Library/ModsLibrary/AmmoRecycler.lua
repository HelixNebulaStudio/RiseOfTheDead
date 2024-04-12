local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};

local RunService = game:GetService("RunService");

local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

local modWeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

if RunService:IsServer() then
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	modOnGameEvents:ConnectEvent("OnNpcDamaged", function(player, damageSource)
		if player == nil then return end;
		
		local profile = shared.modProfile:Get(player);
		if profile == nil then return end;
		
		if damageSource.ToolStorageItem == nil then return end;

		local npcModule = damageSource.NpcModule;
		local maxHealth = npcModule.Humanoid.MaxHealth;
		local damage = damageSource.Damage;

		local storageItem = damageSource.ToolStorageItem;
		local storageItemID = storageItem.ID;

		local weaponModule, weaponClass = profile:GetItemClass(storageItemID);
		if weaponClass ~= "Weapon" then return end;
		
		local currAmmo = storageItem:GetValues("A");
		local newMaxAmmo = (storageItem:GetValues("MA") or weaponModule.Configurations.MaxAmmoLimit) +1;
		
		local damageId = damageSource.DamageId;
		
		if profile.EquippedTools == nil then return end
		if profile.EquippedTools.AmmoRecyclerId == damageId then return end;
		profile.EquippedTools.AmmoRecyclerId = damageId;
		
		local dmgRecyclerValue = weaponModule.Configurations and weaponModule.Configurations.AmmoRecycler

		if dmgRecyclerValue == nil or damage <= maxHealth then return end;
		
		local roll = math.random(0, 1000)/1000;
		if roll > dmgRecyclerValue then return end;
		
		local weaponModel = profile.EquippedTools.WeaponModels and profile.EquippedTools.WeaponModels[1];
		
		if weaponModel and weaponModel.PrimaryPart then
			local sound: Sound = modAudio.Play("AmmoFeed", weaponModel.PrimaryPart)
			sound.Volume = 10;
			sound.PlaybackSpeed = 1.5;
		end
		
		storageItem:SetValues("MA", newMaxAmmo);
		storageItem:Sync({"MA"});
		
		
		--if ammoRecyclerRandom:FairCrit(storageItemID or "", dmgRecyclerMaxChance) then
		--	remoteReloadWeapon:FireClient(player, {Id=storageItemID; MA=newMaxAmmo; UnixTime=DateTime.now().UnixTimestampMillis; AR=true;});
		--	profile.ActiveInventory:SetValues(storageItemID, {MA=newMaxAmmo;});
		--end

		--if profile.EquippedTools.AmmoRecyclerBulletCounter == nil then
		--	profile.EquippedTools.AmmoRecyclerBulletCounter = 0;
		--end
		--profile.EquippedTools.AmmoRecyclerBulletCounter = profile.EquippedTools.AmmoRecyclerBulletCounter + 1;
		--local remainder = math.fmod(profile.EquippedTools.AmmoRecyclerBulletCounter, dmgRecyclerValue);
		
		--if remainder == 0 then
		--	storageItem:SetValues("MA", newMaxAmmo);
		--	storageItem:Sync({"MA"});
		--	--remoteReloadWeapon:FireClient(player, {Id=storageItemID; MA=newMaxAmmo; UnixTime=DateTime.now().UnixTimestampMillis; AR=true;});
		--end
	end)
end


function Mod.Activate(packet)
	local module = packet.WeaponModule;
	
	local layerInfo = modModsLibrary.GetLayer("C", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	if module.Configurations.AmmoRecycler == nil or value < module.Configurations.AmmoRecycler then
		module.Configurations.AmmoRecycler = value;
	end
		
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;

	--local level = math.clamp((values["C"] or 0), 0, info.Upgrades[1].MaxLevel-paramPacket.TierOffset);
	--local freq = ModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, level, info.Upgrades[1].MaxLevel);
	
	--if module.Configurations.AmmoRecycler == nil or freq < module.Configurations.AmmoRecycler then
	--	module.Configurations.AmmoRecycler = freq;
	--end
	
	--local maxChance = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, level, info.Upgrades[1].MaxLevel);
	
	
	--if module.Configurations.AmmoRecycler == nil or maxChance > module.Configurations.AmmoRecycler then
	--	module.Configurations.AmmoRecycler = maxChance;
	--end
end


return Mod;