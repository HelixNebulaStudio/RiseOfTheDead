local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Projectile;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Single;
	
	EquipLoadTime=1.2;
	
	BaseInaccuracy=1.8;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	-- Weapon Properties;
	AmmoLimit=1;
	MaxAmmoLimit=16;
	
	XRecoil=0.0;
	YRecoil=0.0;
	
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(0);

	-- Decorations;
	ShakeCamera=false;
	GeneratesBulletHoles=true;
	GenerateBloodEffect=true;
	GenerateTracers=false;
	GenerateMuzzle=false;
	
	-- Projectile Configurations;
	ProjectileId="arrow";
	
	MinBaseDamage=200;
	BaseDamage=22200;--24200
	
	
	AdsTrajectory=true;
	
	--
	CanUnfocusFire = false;
	BaseFocusDuration=4;
	FocusDuration=4;
	FocusWalkSpeedReduction=0.55;
	ChargeDamagePercent=1;

	OnPrimaryFire = function(weaponModel, modWeaponModule)
		local arrow = weaponModel:FindFirstChild("Arrow");
		if arrow then
			arrow.Transparency = 1;
			delay(0.5, function()
				modWeaponModule.Configurations.OnAmmoUpdate(weaponModel, modWeaponModule);
			end)
		end
	end;
	
	OnAmmoUpdate = function(weaponModel, modWeaponModule)
		local properties = modWeaponModule.Properties;
		local arrow = weaponModel:FindFirstChild("Arrow");
		
		if arrow and properties.Ammo and properties.MaxAmmo then
			arrow.Transparency = (properties.MaxAmmo <= 0 and properties.Ammo <= 0) and 1 or 0;
		end
	end;
	
	CustomDpsCal = function(self)
		local dmg = self.Configurations.Damage;
		local focusTime = self.Configurations.FocusDuration;
		local reloadspeed = self.Properties.ReloadSpeed;
		
		return dmg/focusTime;--math.max(focusTime, reloadspeed);
	end;
	CustomDpmCal = function(self)
		return;
	end;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=600;
	FireRate=(60/600);
	ReloadSpeed=1;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16722692548;};
	Focus={Id=16722696313};
	FocusCore={Id=16722697947};
	Inspect={Id=16722699639;};
	PrimaryFire={Id=16722701955;};
	Reload={Id=16722704430;};
	Load={Id=16722704430;};
	
} or {
	Core={Id=16722692548;};
	Focus={Id=16722696313};
	FocusCore={Id=16722697947};
	Inspect={Id=16722699639;};
	PrimaryFire={Id=16722701955;};
	Reload={Id=16722704430;};
	Load={Id=16722704430;};
};
--Core={Id=5458879197;};
--Focus={Id=5459215157};
--FocusCore={Id=6469870633};
--Inspect={Id=5463228356;};
--Load={Id=5463113974;};
--PrimaryFire={Id=5462823361;};
--Empty={Id=5458879197;};
--Reload={Id=5463113974;};
--Unequip={Id=7144983768};

local Audio={
	Load={Id=609338076; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=609348009; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0;};
	Reload={Id=609338076; Pitch=1.1; Volume=0.6;};
	--ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
};

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);