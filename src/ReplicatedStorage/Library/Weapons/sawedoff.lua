local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Single;
	WeaponType=Library.WeaponType.Shotgun;
	
	EquipLoadTime=0.55;
	
	AmmoType="shotgunammo";
	
	BaseInaccuracy=7;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.5;
	MovingInaccuracyScale=2.3;
	
	BulletRange=512;
	BulletEject="ShotgunBullet";
	BulletEjectDelayTime=0.1;
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.1;
	YRecoil=0.6;
	
	-- Weapon Properties;
	MinBaseDamage=60;
	BaseDamage=624;
	
	AmmoLimit=8;
	MaxAmmoLimit=(8*4);
	
	PenatrationStrength=1; -- In studs.
	PenatrationDamageReduction=0.5; -- Damage * PenatrationDamageReduction;
	
	DamageDropoff={
		MinDistance=86;
		MaxDistance=128;
	};
	
	BaseHeadshotMultiplier=0.02;
	-- UI Configurations;
	UISpreadIntensity=5;
	
	-- Body
	RecoilStregth=math.rad(120);
	
	BasePiercing=2;
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Shotgun;
	KillImpulseForce=20;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=80.59;
	FireRate=(60/80.59);
	ReloadSpeed=0.6;
	BaseMultishot={Min=4, Max=6};
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16276739060;};
	PrimaryFire={Id=16276745393;};
	Reload={Id=16276748009;};
	Load={Id=16276751205;};
	Inspect={Id=16276754008;};
	Sprint={Id=16276887371};
	Empty={Id=16276756420;};
	Unequip={Id=7144983768};
	Idle={Id=17557363942};

} or { -- Main
	Core={Id=16276739060;};
	PrimaryFire={Id=16276745393;};
	Reload={Id=16276748009;};
	Load={Id=16276751205;};
	Inspect={Id=16276754008;};
	Sprint={Id=16276887371};
	Empty={Id=16276756420;};
	Unequip={Id=7144983768};
	Idle={Id=17557363942};
	
};


local Audio={
	Load={Id=169799883; Pitch=1; Volume=0.4;};
	PrimaryFire={Id=168413145; Pitch=1; Volume=0.6;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	Reload={Id=5677987779; Pitch=1; Volume=0.6;};
}

local toolPackage = {
	ItemId="sawedoff";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Shotgun";
	Tier=1;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;