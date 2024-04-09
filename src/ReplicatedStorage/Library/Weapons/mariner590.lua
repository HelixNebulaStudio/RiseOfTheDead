local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Single;
	WeaponType=Library.WeaponType.Shotgun;
	
	EquipLoadTime=0.5;
	
	AmmoType="shotgunammo";
	
	BaseInaccuracy=4;
	FocusInaccuracyReduction=0.8;
	CrouchInaccuracyReduction=0.8;
	MovingInaccuracyScale=2;
	
	BulletRange=512;
	BulletEject="ShotgunBullet";
	BulletEjectDelayTime=0.1;
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.06;
	YRecoil=0.35;
	
	-- Weapon Properties;
	MinBaseDamage=100;
	BaseDamage=1040;
	
	AmmoLimit=12;
	MaxAmmoLimit=(12*3);
	
	PenatrationStrength=1; -- In studs.
	PenatrationDamageReduction=0.5; -- Damage * PenatrationDamageReduction;
	
	DamageDropoff={
		MinDistance=86;
		MaxDistance=160;
	};
	
	BaseHeadshotMultiplier=0.02;
	-- UI Configurations;
	UISpreadIntensity=5;
	
	-- Body
	RecoilStregth=math.rad(120);

	BasePiercing=1;
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Shotgun;
	KillImpulseForce=20;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=180;
	FireRate=(60/180);
	ReloadSpeed=0.35;
	BaseMultishot={Min=3, Max=4};
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16290100998;};
	PrimaryFire={Id=16290102224;};
	Reload={Id=16290103942;};
	Load={Id=16290104991;};
	Inspect={Id=16290106088;};
	Sprint={Id=16290107511};
	Empty={Id=16290108827;};
	Unequip={Id=16838937257};

} or { -- Main
	Core={Id=16635249868;};
	PrimaryFire={Id=16635256576;};
	Reload={Id=16635257791;};
	Load={Id=16635255273;};
	Inspect={Id=16635253551;};
	Sprint={Id=16635267162};
	Empty={Id=16635250983;};
	Unequip={Id=16838937257};
	
};

local Audio={
	Load={Id=169799883; Pitch=1; Volume=0.4;};
	PrimaryFire={Id=185044507; Pitch=1; Volume=2;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	Reload={Id=3299778220; Pitch=0.8; Volume=0.6;};
}

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);