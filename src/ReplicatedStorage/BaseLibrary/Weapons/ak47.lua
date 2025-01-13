local WeaponAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponAttributes.TriggerModes.Automatic;
	ReloadMode=WeaponAttributes.ReloadModes.Full;
	WeaponType=WeaponAttributes.WeaponType.Rifle;
	
	EquipLoadTime=0.75;
	
	AmmoType="heavyammo";
	
	BaseInaccuracy=2.6;
	FocusInaccuracyReduction=0.7;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=2;
	InaccDecaySpeed=1.6;
	
	BulletRange=512;
	BulletEject="RifleBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
	
	XRecoil=0.02;
	YRecoil=0.055;
	
	-- Weapon Properties;
	MinBaseDamage=36;
	BaseDamage=735;
	
	AmmoLimit=35;
	MaxAmmoLimit=(35*5);
	
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
	Rpm=600;
	FireRate=(60/600);
	ReloadSpeed=3.5;
}

local Animations={
	Core={Id=101306375716410;};
	PrimaryFire={Id=70943120517800; FocusWeight=0.1};
	Reload={Id=84738551600224;};
	Load={Id=83642360885833;};
	Inspect={Id=77627305926334;};
	Sprint={Id=111816464911275};
	Empty={Id=83248312199973;};
	Unequip={Id=89539360837699};
	Idle={Id=93746259969778};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1926397389; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId="ak47";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Rifle";
	Tier=1;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;