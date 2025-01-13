local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBitFlags = require(game.ReplicatedStorage.Library.BitFlags);

---
local ItemPacket = {};
local HitListBitFlag;

function ItemPacket.GetTurretConfigs()
	local defaultHitlistBitString = HitListBitFlag.Size; -- all bits =1
	defaultHitlistBitString = HitListBitFlag:Set(defaultHitlistBitString, "Witherer", false);
	
	return {
		TargetDistancePriority={
			Order = 1;
			Title = "Distance Priority";
			Desc = "Which distance to prioritize shooting first.";
			Options = {"Closest"; "Furthest"; "Random";};
		};
		TargetHealthPriority={
			Order = 2;
			Title = "Health Priority";
			Desc = "Which health to prioritize shooting first.";
			Options = {"Lowest"; "Highest"; "Random";};
		};
		TargetSpeedPriority={
			Order = 3;
			Title = "Speed Priority";
			Desc = "Which speed to prioritize shooting first.";
			Options = {"Fastest"; "Slowest";};
		};
		CrowdFire={
			Order = 4;
			Title = "Crowd Firing Mode";
			Desc = "Only fire when there are multiple hostiles.";
			Options = {"Disabled"; "5"; "10"; "15"; "20";};
		};
		CapFireRate={
			Order = 5;
			Title = "Cap Fire Rate";
			Desc = "Limiting rate of fire to a minimum rpm to conserve ammo.";
			Options = {"Uncapped"; "600 RPM"; "450 RPM"; "300 RPM"; "150 RPM"; "100 RPM"; "60 RPM"; "30 RPM"};
			OptionValues = {0; 600; 450; 300; 150; 100; 60; 30;};
		};
		ChargeFocus={
			Order = 6;
			Title = "Charge Focus";
			Desc = "Only shoot when focus is fully charged for weapons with focus.";
			Options = {"Disabled"; "Enabled";};
		};
		ToxicBarrage={
			Order = 7;
			Title = "Toxic Barrage Mode";
			Desc = "Enable to target enemies that are not affected by Toxic Barrage first.";
			Options = {"Disabled"; "Enabled";};
		};
		Frostbite={
			Order = 8;
			Title = "Frostbite Mode";
			Desc = "Enable to target enemies that are not affected Frozen first.";
			Options = {"Disabled"; "Enabled";};
		};
		DebuffOnly={
			Order = 9;
			Title = "Debuff Only";
			Desc = "Only shoot to debuff and not shoot to kill.";
			Options = {"Disabled"; "Enabled";};
		};
		UseHitlist={
			Order = 10;
			Title = "Use Custom Hitlist";
			Desc = "Use custom hitlist checklist.";
			Options = {"Disabled"; "Enabled";};
			CustomPrompt = "HitList";
			
			HitListBitFlag = HitListBitFlag;
			DefaultBitString = defaultHitlistBitString;
		};
	};
end

function ItemPacket.Init(itemLib)
	HitListBitFlag = modBitFlags.new();
	HitListBitFlag:AddFlag("Zombie", 1);
	HitListBitFlag:AddFlag("Ticks", 2);
	HitListBitFlag:AddFlag("Leaper", 3);
	HitListBitFlag:AddFlag("Heavy", 4);
	HitListBitFlag:AddFlag("Bloater", 5);
	HitListBitFlag:AddFlag("Growler", 6);
	HitListBitFlag:AddFlag("Dr. Sinister", 7);
	HitListBitFlag:AddFlag("Tendrils", 8);
	HitListBitFlag:AddFlag("Witherer", 9);
	HitListBitFlag:AddFlag("Bandit", 10);
	HitListBitFlag:AddFlag("Bosses", 11);

	--== MARK: Server
	if RunService:IsClient() then return end;
	
	local modAudio = require(game.ReplicatedStorage.Library.Audio);
	local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
	local remoteAutoTurret = modRemotesManager:Get("AutoTurret");
	
	local TurretConfigs = itemLib.GetTurretConfigs();
	
	function remoteAutoTurret.OnServerInvoke(player, action, ...)
		local profile = shared.modProfile:Get(player);
		local playerSave = profile:GetActiveSave();

		local patStorage = shared.modStorage.Get("portableautoturret", player);
		local accessorySiid = patStorage.Values.Siid;
		
		local accessoryStorageItem = shared.modStorage.FindIdFromStorages(accessorySiid, player);

		local accessories = playerSave.AppearanceData:GetAccessories(accessorySiid);
		if accessories == nil then return end;
		
		local accessory = accessories[1];
		local turretArm = accessory:WaitForChild("turretArm");
		
		----
		local rPacket = {};

		local accessorySiid = accessory:GetAttribute("StorageItemId");
		if accessorySiid == nil then
			Debugger:Warn("Missing WeaponStorageItemID");
			return rPacket;
		end

		local weaponStorageItem = patStorage:FindByIndex(1);
		local batteryStorageItem = patStorage:FindByIndex(2);

		if action == "toggleonline" then
			local onlineBool = not (accessoryStorageItem:GetValues("Online") == true);

			if onlineBool then
				if weaponStorageItem == nil then
					shared.Notify(player, "A weapon is required in the weapon slot.", "Negative");
					return rPacket;
				end

				if batteryStorageItem == nil or batteryStorageItem.ItemId ~= "battery" then
					shared.Notify(player, "A battery with power is required in the battery slot.", "Negative");
					return rPacket;
				end
			end

			if onlineBool then
				modAudio.Play("TurretOnline", turretArm.PrimaryPart); 
			else
				modAudio.Play("TurretOffline", turretArm.PrimaryPart); 
			end

			accessoryStorageItem:SetValues("Online", onlineBool):Sync{"Online"};
			
			rPacket.ID = accessoryStorageItem.ID;
			rPacket.Values = accessoryStorageItem.Values;
			rPacket.Success = true;
			
			accessory:SetAttribute("Update", true);

			return rPacket;

		elseif action == "resetconfig" then

			accessoryStorageItem:SetValues("Config", {}):Sync{"Config"};
			rPacket.Values = accessoryStorageItem.Values;
			rPacket.Success = true;

			return rPacket;

		elseif action == "config" then
			local packet = ...;

			local configKey = packet.ConfigKey;
			local optionIndex = packet.OptionIndex;

			local configValues = accessoryStorageItem:GetValues("Config") or {};
			local configInfo = TurretConfigs[packet.ConfigKey];

			if configInfo == nil then return rPacket end;

			configValues[configKey] = optionIndex;
			if configValues[configKey] == 1 then
				configValues[configKey] = nil;
			end

			accessoryStorageItem:SetValues("Config", configValues):Sync{"Config"};
			rPacket.Values = accessoryStorageItem.Values;
			rPacket.Success = true;

			return rPacket;

		elseif action == "config:UseHitlist" then
			local packet = ...;

			local flagTag = packet.HitlistTag;
			local flagVal = packet.FlagValue == true;

			local configInfo = TurretConfigs.UseHitlist;
			local configHitlistBitFlags = configInfo.HitListBitFlag;

			if configHitlistBitFlags:HasFlag(flagTag) == nil then return rPacket end;

			local configValues = accessoryStorageItem:GetValues("Config") or {};

			local userHitlistBitString = configValues.Hitlist or configInfo.DefaultBitString;

			configValues.Hitlist = configHitlistBitFlags:Set(userHitlistBitString, flagTag, flagVal);
			accessoryStorageItem:SetValues("Config", configValues):Sync{"Config"};

			rPacket.FlagVal = configHitlistBitFlags:Test(flagTag, userHitlistBitString);
			rPacket.Success = true;

			return rPacket;
			
		elseif action == "syncjoints" then
			local packet = ...;
			
			local angleYaw = packet[1];
			local anglePitch = packet[2];
			
			if angleYaw == nil or anglePitch == nil then return end;
			
			turretArm:SetAttribute("AngleYaw", angleYaw);
			turretArm:SetAttribute("AnglePitch", anglePitch);
			
			return;
		end

	end
	
end

return ItemPacket;