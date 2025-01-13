local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Automatic;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	WeaponType=WeaponsAttributes.WeaponType.Rifle;
	
	EquipLoadTime=0.75;
	
	AmmoType="heavyammo";
	
	BaseInaccuracy=2.3;
	FocusInaccuracyReduction=1.2;
	CrouchInaccuracyReduction=0.4;
	MovingInaccuracyScale=3;
	InaccDecaySpeed=1.3;
	
	BulletRange=768;
	BulletEject="RifleBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

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

local Animations={
	Core={Id=88923968392235;};
	PrimaryFire={Id=77503593542774; FocusWeight=0.05};
	Reload={Id=93218667491748;};
	TacticalReload={Id=129908758182155;};
	Load={Id=138698020933254;};
	Inspect={Id=91108936982761;};
	Sprint={Id=138493413350832};
	Empty={Id=105115278683312;};
	Unequip={Id=89539360837699};
	Idle={Id=137418388069757};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1926370239; Pitch=1; Volume=1;};--2697431
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId="m4a4";
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