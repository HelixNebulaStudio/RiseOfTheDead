local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Projectile;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Full;
	
	EquipLoadTime=1.2;
	
	BaseInaccuracy=1.8;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	-- Weapon Properties;
	AmmoLimit=6;
	MaxAmmoLimit=(6*3);
	
	XRecoil=0.0;
	YRecoil=0.0;
	
	-- UI Configurations;
	UISpreadIntensity=4;

	UseScopeGui=true;
	-- Body
	RecoilStregth=math.rad(10);
	
	-- Decorations;
	ShakeCamera=false;
	GeneratesBulletHoles=true;
	GenerateBloodEffect=true;
	GenerateTracers=false;
	GenerateMuzzle=false;
	
	-- Projectile Configurations;
	ProjectileId="boltarrow";
	
	MinBaseDamage=120;
	BaseDamage=16500;
	
	AdsTrajectory=true;
	
	--
	BaseFocusDuration=1;
	FocusDuration=1;
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
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=42;
	FireRate=(60/42);
	ReloadSpeed=5.3;
};

local Animations = workspace:GetAttribute("IsDev") and {
	Core={Id=16774284448;};
	Inspect={Id=17031532267;};
	Inspect2={Id=16774287706;};
	Load={Id=16774291546;};
	PrimaryFire={Id=16774293377; FocusWeight=0.2};
	Empty={Id=16774286179;};
	Reload={Id=16774296015;};
	TacticalReload={Id=16774298008;};
	Unequip={Id=16840085976};
	Sprint={Id=10400582802};
	LastFire={Id=16774289860;};
	Idle={Id=16883924242};

} or { -- Main
	Core={Id=16774284448;};
	Inspect={Id=17031532267;};
	Inspect2={Id=16774287706;};
	Load={Id=16774291546;};
	PrimaryFire={Id=16774293377; FocusWeight=0.2};
	Empty={Id=16774286179;};
	Reload={Id=16774296015;};
	TacticalReload={Id=16774298008;};
	Unequip={Id=16840085976};
	Sprint={Id=10400582802};
	LastFire={Id=16774289860;};
	Idle={Id=16883924242};
	
};

local Audio={
	Load={Id=609338076; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=13314698002; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0;};
	--Reload={Id=7108953542; Pitch=1.1; Volume=0.6;};
};

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);