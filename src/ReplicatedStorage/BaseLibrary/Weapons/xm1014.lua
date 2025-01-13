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
	
	BaseInaccuracy=4;
	FocusInaccuracyReduction=0.6;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=2;
	
	BulletRange=512;
	BulletEject="ShotgunBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.08;
	YRecoil=0.4;
	
	-- Weapon Properties;
	MinBaseDamage=30;
	BaseDamage=312;
	
	AmmoLimit=12;
	MaxAmmoLimit=(12*4);
	
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
	Rpm=171.43;
	FireRate=(60/171.43);
	ReloadSpeed=0.5;
	BaseMultishot={Min=3, Max=4};
}

local Animations={
	Core={Id=93348252047486;};
	PrimaryFire={Id=121781410672221;};
	Reload={Id=93109076287372;};
	Load={Id=116742008633662;};
	Inspect={Id=137561504669780;};
	Sprint={Id=82469941829232};
	Empty={Id=105044054803916;};
	Unequip={Id=126196627858337};
	Idle={Id=80806253952071};
};

local Audio={
	Load={Id=169799883; Pitch=1; Volume=0.4;};
	PrimaryFire={Id=2697294; Pitch=1; Volume=0.5;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	Reload={Id=5677987779; Pitch=1.1; Volume=0.6;}; --2697295
}

local toolPackage = {
	ItemId="xm1014";
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