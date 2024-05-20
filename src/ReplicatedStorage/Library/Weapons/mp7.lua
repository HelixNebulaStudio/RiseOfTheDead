local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.SMG;
	
	EquipLoadTime=0.6;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=6;
	FocusInaccuracyReduction=0;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=2;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.04;
	YRecoil=0.06;
	
	-- Weapon Properties;
	MinBaseDamage=26;
	BaseDamage=380;
	
	AmmoLimit=64;
	MaxAmmoLimit=(64*4);
	
	DamageDropoff={
		MinDistance=48;
		MaxDistance=100;
	};
	
	BaseHeadshotMultiplier=0.05;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(80);
	
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable["Submachine gun"];
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=750;
	FireRate=(60/750);
	ReloadSpeed=2.3;--2.1;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16355090581;};
	PrimaryFire={Id=16355106244; FocusWeight=0.1};
	Reload={Id=16355108599;};
	TacticalReload={Id=16355114738;};
	Load={Id=16355103861;};
	Inspect={Id=16355097298;};
	Sprint={Id=16355110604};
	Empty={Id=16355093013;};
	Unequip={Id=16838914873};
	Idle={Id=17557546311;};
	
} or { -- Main
	Core={Id=16355090581;};
	PrimaryFire={Id=16355106244; FocusWeight=0.1};
	Reload={Id=16355108599;};
	TacticalReload={Id=16355114738;};
	Load={Id=16355103861;};
	Inspect={Id=16355097298;};
	Sprint={Id=16355110604};
	Empty={Id=16355093013;};
	Unequip={Id=16838914873};
	Idle={Id=17557546311;};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1926370458; Pitch=1.7; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);