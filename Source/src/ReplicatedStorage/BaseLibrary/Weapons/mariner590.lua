local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Semi;
	ReloadMode=WeaponsAttributes.ReloadModes.Single;
	WeaponType=WeaponsAttributes.WeaponType.Shotgun;
	
	EquipLoadTime=0.5;
	
	AmmoType="shotgunammo";
	
	BaseInaccuracy=4;
	FocusInaccuracyReduction=0.8;
	CrouchInaccuracyReduction=0.8;
	MovingInaccuracyScale=2;
	
	BulletRange=512;
	BulletEject="ShotgunBullet";
	BulletEjectDelayTime=0.1;
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

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

local Animations={
	Core={Id=119812751979835;};
	PrimaryFire={Id=91267786732266;};
	Reload={Id=101087315049852;};
	Load={Id=112951965982569;};
	Inspect={Id=125651503210341;};
	Sprint={Id=100237466610388};
	Empty={Id=127657384790191;};
	Unequip={Id=126196627858337};
	Idle={Id=134015118232808};
};

local Audio={
	Load={Id=169799883; Pitch=1; Volume=0.4;};
	PrimaryFire={Id=185044507; Pitch=1; Volume=2;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	Reload={Id=3299778220; Pitch=0.8; Volume=0.6;};
}

local toolPackage = {
	ItemId="mariner590";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Shotgun";
	Tier=2;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;
