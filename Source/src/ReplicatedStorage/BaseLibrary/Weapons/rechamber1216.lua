local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Automatic;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	WeaponType=WeaponsAttributes.WeaponType.Shotgun;
	
	EquipLoadTime=1;
	
	AmmoType="shotgunammo";
	
	BaseInaccuracy=4;
	FocusInaccuracyReduction=0.8;
	CrouchInaccuracyReduction=0.8;
	MovingInaccuracyScale=4;
	
	BulletRange=512;
	BulletEject="ShotgunBullet";
	BulletEjectDelayTime=0.1;
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.08;
	YRecoil=0.4;
	
	-- Weapon Properties;
	MinBaseDamage=80;
	BaseDamage=2460;
	
	AmmoLimit=16;
	MaxAmmoLimit=(16*3);
	
	PenatrationStrength=1; -- In studs.
	PenatrationDamageReduction=0.5;
	
	DamageDropoff={
		MinDistance=86;
		MaxDistance=128;
	};
	
	BaseHeadshotMultiplier=0.02;
	-- UI Configurations;
	UISpreadIntensity=6;
	
	KnockoutTrigger="Modifier";
	KnockoutDistance=8;
	KnockoutDuration=2;

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
	Rpm=100;
	FireRate=(60/100);
	ReloadSpeed=3;
	BaseMultishot={Min=4, Max=4};
}

local Animations={
	Core={Id=118165259321661;};
	PrimaryFire={Id=105143866671646;};
	Rechamber={Id=104823008777529;};
	Reload={Id=78609558013599;};
	TacticalReload={Id=114901408445746;}; 
	Load={Id=123553649109228;};
	Inspect={Id=78694668343797;};
	Sprint={Id=112949620867848};
	Empty={Id=112949620867848;};
	LastFire={Id=103834737888365;};
	Unequip={Id=126196627858337};
	Idle={Id=116654596081777};
};

local Audio={
	Load={Id=169799883; Pitch=1.3; Volume=0.4;};
	PrimaryFire={Id=72945517149917; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	ShotgunHandle={Id="ShotgunHandle"; Preload=true;};
	ShotgunPump2={Id="ShotgunPump2"; Preload=true;};
	LoadShotgunShell={Id="LoadShotgunShell"; Preload=true;};
}

local toolPackage = {
	ItemId=script.Name;
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Shotgun";
	Tier=5;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;