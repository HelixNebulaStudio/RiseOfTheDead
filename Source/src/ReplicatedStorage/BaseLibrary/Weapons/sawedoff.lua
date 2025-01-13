local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Semi;
	ReloadMode=WeaponsAttributes.ReloadModes.Single;
	WeaponType=WeaponsAttributes.WeaponType.Shotgun;
	
	EquipLoadTime=0.55;
	
	AmmoType="shotgunammo";
	
	BaseInaccuracy=7;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.5;
	MovingInaccuracyScale=2.3;
	
	BulletRange=512;
	BulletEject="ShotgunBullet";
	BulletEjectDelayTime=0.1;
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

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

local Animations={
	Core={Id=123045133841238;};
	PrimaryFire={Id=94597869397556;};
	Reload={Id=83798355489956;};
	Load={Id=74756836685661;};
	Inspect={Id=133379356507494;};
	Sprint={Id=110582874169322};
	Empty={Id=102360623642476;};
	Unequip={Id=126196627858337};
	Idle={Id=92395807073947};
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