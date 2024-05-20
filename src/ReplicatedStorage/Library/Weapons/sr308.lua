local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.Rifle;
	
	EquipLoadTime=1.2;
	
	AmmoType="heavyammo";
	
	BaseInaccuracy=3;
	FocusInaccuracyReduction=1.2;
	CrouchInaccuracyReduction=0.4;
	MovingInaccuracyScale=3;
	InaccDecaySpeed=1;
	
	BulletRange=768;
	BulletEject="RifleBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.06;
	YRecoil=0.1;
	
	-- Weapon Properties;
	MinBaseDamage=64;
	BaseDamage=1306;
	
	CritChance=0.3;
	BaseCritMulti=0.5;
	
	AmmoLimit=28;
	MaxAmmoLimit=(28*3);
	
	DamageDropoff={
		MinDistance=260;
		MaxDistance=400;
	};
	
	BaseHeadshotMultiplier=0.05;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(110);
	WaistRotation=math.rad(70);
	ThirdPersonWaistOffset=math.rad(5);

	AimDownViewModel=CFrame.new(-0.738653421, -0.759163916, 0.851884305, 0.999161422, 0.0121332984, -0.0391057022, -0.0117350435, 0.999877095, 0.0103975851, 0.0392270498, -0.00992995873, 0.999181032);

	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Rifle;
	KillImpulseForce=20;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=360;
	FireRate=(60/360);
	ReloadSpeed=3;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16403626145;};
	PrimaryFire={Id=16403636151; FocusWeight=0.1};
	Reload={Id=16403639875;};
	TacticalReload={Id=16403644604;};
	Load={Id=16403633521;};
	Inspect={Id=16403631384;};
	Sprint={Id=16403642280};
	Empty={Id=16403628750;};
	Unequip={Id=16840085976};
	Idle={Id=16883924242};

} or { -- Main
	Core={Id=16403626145;};
	PrimaryFire={Id=16403636151; FocusWeight=0.1};
	Reload={Id=16403639875;};
	TacticalReload={Id=16403644604;};
	Load={Id=16403633521;};
	Inspect={Id=16403631384;};
	Sprint={Id=16403642280};
	Empty={Id=16403628750;};
	Unequip={Id=16840085976};
	Idle={Id=16883924242};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=7105581785; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);