	local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.Rifle;
	
	EquipLoadTime=0.75;
	
	AmmoType="heavyammo";
	
	BaseInaccuracy=2.3;
	FocusInaccuracyReduction=1.2;
	CrouchInaccuracyReduction=0.4;
	MovingInaccuracyScale=3;
	InaccDecaySpeed=1.3;
	
	BulletRange=768;
	BulletEject="RifleBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.02;
	YRecoil=0.03;
	
	-- Weapon Properties;
	MinBaseDamage=30;
	BaseDamage=612;
	
	AmmoLimit=30;
	MaxAmmoLimit=(30*5);
	
	DamageDropoff={
		MinDistance=200;
		MaxDistance=400;
	};
	
	BaseHeadshotMultiplier=0.1;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(110);

	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Rifle;
	KillImpulseForce=10;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=666;
	FireRate=(60/666);
	ReloadSpeed=3;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16500420231;};
	PrimaryFire={Id=16500425509; FocusWeight=0.05};
	Reload={Id=16500428622;};
	TacticalReload={Id=16500432869;};
	Load={Id=16500423928;};
	Inspect={Id=16500417502;};
	Sprint={Id=16500430718};
	Empty={Id=16500421868;};
	Unequip={Id=16840085976};
	Idle={Id=16883924242};

} or { -- Main
	Core={Id=16649847370;};
	PrimaryFire={Id=16649848801; FocusWeight=0.05};
	Reload={Id=16649850922;};
	TacticalReload={Id=16649852812;};
	Load={Id=16649854872;};
	Inspect={Id=16649858201;};
	Sprint={Id=16649860005};
	Empty={Id=16649867622;};
	Unequip={Id=16840085976};
	Idle={Id=16883924242};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1926370239; Pitch=1; Volume=1;};--2697431
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);