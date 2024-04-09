local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.Sniper;
	
	EquipLoadTime=1.65;
	
	AmmoType="sniperammo";
	
	BaseInaccuracy=2;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.5;
	MovingInaccuracyScale=8;
	
	BulletRange=512;
	BulletEject="SniperBullet";
	BulletEjectDelayTime=0.1;
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.12;
	YRecoil=0.56;
	
	-- Weapon Properties;
	MinBaseDamage=420;
	BaseDamage=10710;
	
	AmmoLimit=7;
	MaxAmmoLimit=(7*4);
	
	DamageDropoff={
		MinDistance=240;
	};
	
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);
	
	UseScopeGui=true;
	
	-- Sniper
	BaseFocusDuration=3;
	FocusDuration=3;
	FocusWalkSpeedReduction=0.6;
	ChargeDamagePercent=0.2;

	Penetration=WeaponProperties.PenetrationTable.Sniper;
	KillImpulseForce=40;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=41.24;
	FireRate=(60/41.24);
	ReloadSpeed=3;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16511144885;};
	PrimaryFire={Id=16511163907; FocusWeight=1};
	PrimaryFire2={Id=16511188571; FocusWeight=1};
	Reload={Id=16511167352;};
	TacticalReload={Id=16511169298;};
	Load={Id=16511186377;};
	Inspect={Id=16511160071;};
	Sprint={Id=16520635824};
	Empty={Id=16511171531;};
	Unequip={Id=16838937257};
	
} or { -- Main
	Core={Id=16511144885;};
	PrimaryFire={Id=16511163907; FocusWeight=1};
	PrimaryFire2={Id=16511188571; FocusWeight=1};
	Reload={Id=16511167352;};
	TacticalReload={Id=16511169298;};
	Load={Id=16511186377;};
	Inspect={Id=16511160071;};
	Sprint={Id=16520635824};
	Empty={Id=16511171531;};
	Unequip={Id=16838937257};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1953832141; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);