local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.Rifle;
	
	EquipLoadTime=1;
	
	AmmoType="heavyammo";
	
	BaseInaccuracy=2.6;
	FocusInaccuracyReduction=0.7;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=2.5;
	InaccDecaySpeed=0.5;
	
	BulletRange=512;
	BulletEject="RifleBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.02;
	YRecoil=0.05;
	
	-- Weapon Properties;
	MinBaseDamage=42;
	BaseDamage=857;
	
	AmmoLimit=20;
	MaxAmmoLimit=(20*4);
	
	DamageDropoff={
		MinDistance=200;
		MaxDistance=400;
	};
	
	BaseHeadshotMultiplier=0.1;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Rifle;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=700;
	FireRate=(60/700);
	ReloadSpeed=1.5;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16425676780;};
	PrimaryFire={Id=16425742050; FocusWeight=0.05};
	Reload={Id=16425745130;};
	TacticalReload={Id=16425749032;};
	Load={Id=16436351064;};
	Inspect={Id=16425735473;};
	Sprint={Id=16425726226};
	Empty={Id=16425693404;};
	Unequip={Id=16840085976};
	Idle={Id=17557607357};

} or { -- Main
	Core={Id=16425676780;};
	PrimaryFire={Id=16425742050; FocusWeight=0.05};
	Reload={Id=16425745130;};
	TacticalReload={Id=16425749032;};
	Load={Id=16436351064;};
	Inspect={Id=16425735473;};
	Sprint={Id=16425726226};
	Empty={Id=16425693404;};
	Unequip={Id=16840085976};
	Idle={Id=17557607357};
	
};


local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1926397389; Pitch=0.6; Volume=1;};--168436671
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	Reload={Id=144798533; Pitch=1; Volume=0.6;};
}

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);