local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local Weapon = {};


local function update(base, new)
	for key, value in pairs(new) do
		if type(value) == "table" and value.Min == nil and value.Max == nil then
			update(base[key], value);
		else
			base[key] = value;
		end
	end
end

function Weapon.new(configurations, properties, animations, audio)
	local Configurations={
		WeaponName="P250";
		-- Weapon Mechanics;
		BulletMode=Library.BulletModes.Hitscan;
		TriggerMode=Library.TriggerModes.Semi;
		ReloadMode=Library.ReloadModes.Full;
		
		BaseInaccuracy=1;
		Inaccuracy=configurations.BaseInaccuracy;
		
		BaseFocusInaccuracyReduction=0.5;
		FocusInaccuracyReduction=configurations.BaseFocusInaccuracyReduction;
		
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=1.3;
		InaccDecaySpeed=1;
		
		XRecoil=0.01;
		YRecoil=0.02;

		MinBaseDamage=20;
		PreModDamage=configurations.MinBaseDamage;
		Damage=configurations.MinBaseDamage;
		
		CritMulti=configurations.BaseCritMulti;
		
		BulletRange=512;
		-- Weapon Properties;
		AmmoLimit=12;
		MaxAmmoLimit=72;
		
		DamageDropoff={
			MinDistance=64;
			MaxDistance=512;
		};
		
		HeadshotMultiplier=configurations.BaseHeadshotMultiplier or 1;
		
		-- UI Configurations;
		UISpreadIntensity=5;
		
		-- Body
		RecoilStregth=math.rad(90);
		--WaistRotation=0;
		UseScopeGui=false;
		AimDownEnabled=false;
		
		-- Penetration
		Penetration={
			["Others"]=0;
		};
		
		BasePiercing=0;
		
		EquipLoadTime=0.1;
		
		InfiniteAmmo=nil;
		AutoReload=true;
		-- Decorations;
		ShakeCamera=true;
		GeneratesBulletHoles=true;
		GenerateBloodEffect=true;
		GenerateTracers=true;
		GenerateMuzzle=true;
		
		FocusDuration = 0;
		AmmoCost = 1;
	} :: any;
	Configurations.BaseAmmoLimit = Configurations.AmmoLimit;
	Configurations.BaseMaxAmmoLimit = Configurations.MaxAmmoLimit;
	Configurations.__index = Configurations;
	
	if configurations.AmmoType then
		if configurations.AmmoType == "lightammo" then
			Configurations.AmmoIds={"lightammo"};
			
		elseif configurations.AmmoType == "heavyammo" then
			Configurations.AmmoIds={"heavyammo"};
			
		elseif configurations.AmmoType == "shotgunammo" then
			Configurations.AmmoIds={"shotgunammo"};
			
		elseif configurations.AmmoType == "sniperammo" then
			Configurations.AmmoIds={"sniperammo"};
			
		end
	end

	
	local Properties={
		Reloading=false;
		CancelReload=false;
		CanPrimaryFire=true;
		IsPrimaryFiring=false;
		CanAimDown=false;
		
		Ammo=Configurations.AmmoLimit;
		MaxAmmo=Configurations.MaxAmmoLimit;
		
		Rpm=600;
		BaseRpm=properties.Rpm;
		
		FireRate=(60/600);
		BaseFireRate=properties.FireRate;
		
		Piercing=configurations.BasePiercing;
		
		ReloadSpeed=3;
		BaseReloadSpeed=properties.ReloadSpeed;
		
		Multishot=properties.BaseMultishot or 1;
		
		BasePotential=properties.BasePotential;
		Potential=properties.BasePotential;
	}
	Properties.__index = Properties;
	
	update(Configurations, configurations);
	update(Properties, properties);
	
	if Configurations.TriggerMode == Library.TriggerModes.SpinUp then
		assert(Configurations.SpinUpTime, Configurations.WeaponName.." module missing [Configurations.SpinUpTime] values.");
		assert(Configurations.SpinDownTime, Configurations.WeaponName.." module missing [Configurations.SpinDownTime] values.");
	end
	
	local configurationCache, propertiesCache = {}, {};
	
	local weaponModule = {
		ItemId=configurations.ItemId;
		Class="Weapon";
		Library=Library;
		TriggerMode=Library.TriggerModes;
		ReloadMode=Library.ReloadModes;
		Cache={};
		ArcTracerConfig={};
		ModHooks={};
		ModifierTriggers = {};
		
		Configurations=setmetatable(configurationCache, Configurations);
		Properties=setmetatable(propertiesCache, Properties);
		Animations=animations;
		Audio=audio;
		
		SetConfigurations=function(key, value)
			configurations[key] = value;
			Configurations[key] = value;
		end;
		SetProperties=function(key, value)
			properties[key] = value;
			Properties[key] = value;
		end;
		GetConfigurations=function(key)
			return Configurations[key];
		end;
		GetProperties=function(key)
			return Properties[key];
		end;
		SetActive=function(self, val)
			for k, itemModifier in pairs(self.ModifierTriggers) do
				itemModifier:SetActive(val);
			end
		end;
		Reset=function(self)
			for k, _ in pairs(configurationCache) do configurationCache[k] = nil; end
			for k, _ in pairs(propertiesCache) do propertiesCache[k] = nil; end
			table.clear(self.ArcTracerConfig);
			table.clear(self.ModHooks);
		end;
		CalculateDps=function(self)
			if self.Configurations.CustomDpsCal then
				self.Configurations.Dps = self.Configurations.CustomDpsCal(self);
				return;
			end
			local dmg = self.Configurations.Damage;
			local firerate = 60/self.Properties.Rpm;
			local multishot = self.Properties.Multishot;

			if dmg and firerate and multishot then
				multishot = type(multishot) == "table" and multishot.Max or multishot;
				self.Configurations.Dps = (dmg*multishot)/firerate;
			end
		end;
		CalculateDpm=function(self)
			if self.Configurations.CustomDpmCal then
				self.Configurations.Dpm = self.Configurations.CustomDpmCal(self);
				return;
			end
			local dmg = self.Configurations.Damage;
			local firerate = 60/self.Properties.Rpm;
			local multishot = self.Properties.Multishot;
			local reloadspeed = self.Properties.ReloadSpeed;
			local ammo = self.Configurations.AmmoLimit;

			if dmg and firerate and multishot and reloadspeed and ammo then
				multishot = type(multishot) == "table" and multishot.Max or multishot;
				self.Configurations.Dpm = 60/((ammo*firerate)+reloadspeed)*(dmg*ammo);
			end
		end;
		CalculateMd=function(self)
			local preModDmg = self.Configurations.PreModDamage;
			local dmg = self.Configurations.Damage;
			local ammo = self.Configurations.AmmoLimit;

			local multishot = type(self.Properties.Multishot) == "table" and self.Properties.Multishot.Max or self.Properties.Multishot;

			local revMulti = self.Configurations.DamageRev;
			if revMulti then
				local add = (preModDmg * revMulti);

				self.Configurations.Md = dmg * multishot;
				for a=ammo, 1, -1 do
					self.Configurations.Md = self.Configurations.Md + dmg + (add * math.clamp(1-(a/ammo), 0, 1));
				end

			else
				self.Configurations.Md = dmg * (ammo) * multishot;

			end

			-- Magazine damage;
		end;
		CalculateTad=function(self)
			local dmg = self.Configurations.Damage;
			local ammo = self.Configurations.AmmoLimit;
			local maxAmmo = self.Configurations.MaxAmmoLimit;

			if self.Configurations.Md then
				local ammo = self.Configurations.AmmoLimit;
				local maxAmmo = self.Configurations.MaxAmmoLimit;

				local mags = (maxAmmo/ammo)+1;

				self.Configurations.Tad = self.Configurations.Md * mags;

			else

				local multishot = type(self.Properties.Multishot) == "table" and self.Properties.Multishot.Max or self.Properties.Multishot;
				self.Configurations.Tad = dmg * (ammo+maxAmmo) * multishot;
			end
		end;
		SetPrimaryModHook=function(self, data, modLib)
			local meta = {Library=modLib;};
			meta.__index = meta;
			
			self.ModHooks.PrimaryEffectMod = setmetatable(data, meta);
		end;
		AddModifierTrigger=function(self, storageItem, itemModifier, data)
			local src = itemModifier.Script;
			local id = src.Name;

			if self.ModifierTriggers[id] == nil then
				self.ModifierTriggers[id] = itemModifier:Instance(storageItem);
			end
			local newItemModifier = self.ModifierTriggers[id];
			newItemModifier.StorageItem = storageItem;
			newItemModifier:SetActive(true);

			if data then
				for k, v in pairs(data) do
					newItemModifier[k] = v;
				end
			end
		end;
		LoadModifiers=function(self, weaponStorageItem)
			local keysDict = {};
			for k, v in pairs(configurationCache) do
				if v ~= "Modifier" then continue end;
				keysDict[k] = configurationCache[k];
			end
			for k, v in pairs(configurations) do
				if v ~= "Modifier" then continue end;
				keysDict[k] = configurations[k];
			end
			for k, v in pairs(self.Configurations) do
				if v ~= "Modifier" then continue end;
				keysDict[k] = self.Configurations[k];
			end

			for key, _ in pairs(keysDict) do
				local itemModifier = script[key] and require(script[key]);
				if itemModifier == nil then continue end;

				if self.ModifierTriggers[key] == nil then
					self.ModifierTriggers[key] = itemModifier:Instance();
				end
			end
		end;
	} 
	
	return weaponModule;
end

function Weapon.LoadExternalModifiers()
	local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
	local moddedSelf = modModEngineService:GetModule("WeaponModifiers");
	if moddedSelf then moddedSelf:Init(script); end
end

Weapon.PenetrationTable = {
	["Pistol"] = {
		[Enum.Material.Plastic]=1;
		[Enum.Material.SmoothPlastic]=1;
		[Enum.Material.Glass]=1;
		[Enum.Material.Wood]=1;
		[Enum.Material.WoodPlanks]=1;
		[Enum.Material.Metal]=0.2;
		[Enum.Material.Concrete]=0.2;
		["Others"]=0.1;
	};
	
	["Shotgun"] = {
		[Enum.Material.Plastic]=1;
		[Enum.Material.SmoothPlastic]=1;
		[Enum.Material.Glass]=1;
		[Enum.Material.Wood]=1;
		[Enum.Material.WoodPlanks]=1;
		[Enum.Material.Metal]=0.4;
		[Enum.Material.Concrete]=0.4;
		["Others"]=0.1;
	};

	["Submachine gun"] = {
		[Enum.Material.Plastic]=1;
		[Enum.Material.SmoothPlastic]=1;
		[Enum.Material.Glass]=1;
		[Enum.Material.Wood]=1;
		[Enum.Material.WoodPlanks]=1;
		[Enum.Material.Metal]=0.4;
		[Enum.Material.Concrete]=0.4;
		["Others"]=0.1;
	};
	
	["Rifle"] = {
		[Enum.Material.Plastic]=2;
		[Enum.Material.SmoothPlastic]=2;
		[Enum.Material.Glass]=2;
		[Enum.Material.Wood]=1.5;
		[Enum.Material.WoodPlanks]=1.5;
		[Enum.Material.Metal]=0.75;
		[Enum.Material.Concrete]=0.75;
		["Others"]=0.5;
	};

	["Sniper"] = {
		[Enum.Material.Plastic]=2.5;
		[Enum.Material.SmoothPlastic]=2.5;
		[Enum.Material.Glass]=2.5;
		[Enum.Material.Wood]=2;
		[Enum.Material.WoodPlanks]=2;
		[Enum.Material.Metal]=1.5;
		[Enum.Material.Concrete]=1.5;
		["Others"]=1;
	};

	["Heavy machine gun"] = {
		[Enum.Material.Plastic]=1;
		[Enum.Material.SmoothPlastic]=1;
		[Enum.Material.Glass]=1;
		[Enum.Material.Wood]=1;
		[Enum.Material.WoodPlanks]=1;
		[Enum.Material.Metal]=1;
		[Enum.Material.Concrete]=1;
		["Others"]=1;
	};
}


return Weapon;