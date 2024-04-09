local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Full;
	
	EquipLoadTime=0.5;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=2;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	-- Weapon Properties;
	MinBaseDamage=25;
	BaseDamage=365;
	
	AmmoLimit=15;
	MaxAmmoLimit=(15*5);
	
	DamageDropoff={
		MinDistance=100;
		MaxDistance=200;
	};
	
	BaseHeadshotMultiplier=0.5;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);
	
	
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Pistol;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=330;
	FireRate=(60/330);
	ReloadSpeed=2.5;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16149599943;};
	PrimaryFire={Id=16149603387;};
	Reload={Id=16149610410;};
	TacticalReload={Id=16255070403;};
	Load={Id=16149608972;};
	Inspect={Id=16149607622;};
	Sprint={Id=16184602077};
	Empty={Id=16184529409;};
	Unequip={Id=16838903122};
	
} or { -- Main
	Core={Id=16149599943;};
	PrimaryFire={Id=16149603387;};
	Reload={Id=16149610410;};
	TacticalReload={Id=16255070403;};
	Load={Id=16149608972;};
	Inspect={Id=16149607622;};
	Sprint={Id=16184602077};
	Empty={Id=16184529409;};
	Unequip={Id=16838903122};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=2920959; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
};

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);