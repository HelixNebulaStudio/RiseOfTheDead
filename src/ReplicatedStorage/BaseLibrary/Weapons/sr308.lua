local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Automatic;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	WeaponType=WeaponsAttributes.WeaponType.Rifle;
	
	EquipLoadTime=1.2;
	
	AmmoType="heavyammo";
	
	BaseInaccuracy=3;
	FocusInaccuracyReduction=1.2;
	CrouchInaccuracyReduction=0.4;
	MovingInaccuracyScale=3;
	InaccDecaySpeed=1;
	
	BulletRange=768;
	BulletEject="RifleBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.06;
	YRecoil=0.1;
	
	-- Weapon Properties;
	MinBaseDamage=64;
	BaseDamage=1306;
	
	CritChance=0.3;
	BaseCritMulti=0.5;
	
	AmmoLimit=28;
	MaxAmmoLimit=(28*3);
	
	DamageDropoff={
		MinDistance=260;
		MaxDistance=400;
	};
	
	BaseHeadshotMultiplier=0.05;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(110);
	WaistRotation=math.rad(70);
	ThirdPersonWaistOffset=math.rad(5);

	AimDownViewModel=CFrame.new(-0.738653421, -0.759163916, 0.851884305, 0.999161422, 0.0121332984, -0.0391057022, -0.0117350435, 0.999877095, 0.0103975851, 0.0392270498, -0.00992995873, 0.999181032);

	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Rifle;
	KillImpulseForce=20;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=360;
	FireRate=(60/360);
	ReloadSpeed=3;
}

local Animations={
	Core={Id=85506703518501;};
	PrimaryFire={Id=86732742570968; FocusWeight=0.1};
	Reload={Id=104082389321241;};
	TacticalReload={Id=82291281306811;};
	Load={Id=131796814309386;};
	Inspect={Id=93210490423754;};
	Sprint={Id=88758222364714};
	Empty={Id=72960463780772;};
	Unequip={Id=89539360837699};
	Idle={Id=107692371524559};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=7105581785; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	BRSlidePull={Id="BRSlidePull"; Preload=true;};
	BRSlideRelease={Id="BRSlideRelease"; Preload=true;};
}

local toolPackage = {
	ItemId="sr308";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Rifle";
	Tier=3;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;