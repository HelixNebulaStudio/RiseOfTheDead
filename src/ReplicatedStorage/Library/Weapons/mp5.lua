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
	
	BaseInaccuracy=5.2;
	FocusInaccuracyReduction=0;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.5;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.03;
	YRecoil=0.05;
	
	-- Weapon Properties;
	MinBaseDamage=22;
	BaseDamage=320;
	
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
	Rpm=600;
	FireRate=(60/600);
	ReloadSpeed=2.3;--2.5;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16365549559;};
	PrimaryFire={Id=16365559549; FocusWeight=0.1};
	Reload={Id=16365561404;};
	TacticalReload={Id=16365566463;};
	Load={Id=16365557497;};
	Inspect={Id=16365554984;};
	Sprint={Id=16365563818};
	Empty={Id=16365552533;};
	Unequip={Id=16838914873};
	Idle={Id=17557532685;};
	
} or { -- Main
	Core={Id=16667015087;};
	PrimaryFire={Id=16667021188; FocusWeight=0.1};
	Reload={Id=16667023375;};
	TacticalReload={Id=16667026156;};
	Load={Id=16667028334;};
	Inspect={Id=16667032022;};
	Sprint={Id=16667034501};
	Empty={Id=16667037336;};
	Unequip={Id=16838914873};
	Idle={Id=17557532685;};
	
};


local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1926370458; Pitch=1.1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}


Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);