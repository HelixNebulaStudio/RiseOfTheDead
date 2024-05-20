local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.SMG;
	
	EquipLoadTime=0.3;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=6;
	FocusInaccuracyReduction=0;
	CrouchInaccuracyReduction=2;
	MovingInaccuracyScale=1.5;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);
	GenerateMuzzle=false;
	SuppressorAttached=true;

	XRecoil=0.04;
	YRecoil=0.1;
	
	-- Weapon Properties;
	MinBaseDamage=36;
	BaseDamage=650;
	
	CritChance=0.2;
	BaseCritMulti=1;
	
	AmmoLimit=32;
	MaxAmmoLimit=(32*3);
	
	DamageDropoff={
		MinDistance=140;
		MaxDistance=200;
	};
	
	BaseHeadshotMultiplier=0.01;
	-- UI Configurations;
	UISpreadIntensity=5;
	
	-- Body
	RecoilStregth=math.rad(80);

	-- Penetration
	Penetration=WeaponProperties.PenetrationTable["Submachine gun"];
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=1000;
	FireRate=(60/1000);
	ReloadSpeed=3.5;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16326513624;};
	PrimaryFire={Id=16326523513; FocusWeight=0.1};
	Reload={Id=16326525780;};
	TacticalReload={Id=16326511005;};
	Load={Id=16326521475;};
	Inspect={Id=16326518316;};
	Sprint={Id=16326528548};
	Empty={Id=16326515662;};
	Unequip={Id=16838914873};
	Idle={Id=16883924242};

} or { -- Main
	Core={Id=16326513624;};
	PrimaryFire={Id=16326523513; FocusWeight=0.1};
	Reload={Id=16326525780;};
	TacticalReload={Id=16326511005;};
	Load={Id=16326521475;};
	Inspect={Id=16326518316;};
	Sprint={Id=16326528548};
	Empty={Id=16326515662;};
	Unequip={Id=16838914873};
	Idle={Id=16883924242};
	
};

local Audio={
	PrimaryFire={Id=8527857141; Pitch=1; Volume=0.5;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
};

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);