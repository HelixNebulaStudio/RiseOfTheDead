local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Automatic;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	WeaponType=WeaponsAttributes.WeaponType.SMG;
	
	EquipLoadTime=0.3;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=6;
	FocusInaccuracyReduction=0;
	CrouchInaccuracyReduction=2;
	MovingInaccuracyScale=1.5;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
	GenerateMuzzle=false;
	SuppressorAttached=true;

	XRecoil=0.04;
	YRecoil=0.1;
	
	-- Weapon Properties;
	MinBaseDamage=36;
	BaseDamage=650;
	
	CritChance=0.2;
	BaseCritMulti=1;
	
	AmmoLimit=32;
	MaxAmmoLimit=(32*3);
	
	DamageDropoff={
		MinDistance=140;
		MaxDistance=200;
	};
	
	BaseHeadshotMultiplier=0.01;
	-- UI Configurations;
	UISpreadIntensity=5;
	
	-- Body
	RecoilStregth=math.rad(80);

	-- Penetration
	Penetration=WeaponProperties.PenetrationTable["Submachine gun"];
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=1000;
	FireRate=(60/1000);
	ReloadSpeed=3.5;
}

local Animations={
	Core={Id=72559255441025;};
	PrimaryFire={Id=94653477013260; FocusWeight=0.1};
	Reload={Id=106331252112306;};
	TacticalReload={Id=110913881329529;};
	Load={Id=95814606021951;};
	Inspect={Id=118806824562130;};
	Sprint={Id=120436377699689};
	Empty={Id=128820027972640;};
	Unequip={Id=109110694888868};
	Idle={Id=87298881191116};
};

local Audio={
	PrimaryFire={Id=8527857141; Pitch=1; Volume=0.5;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	LightMagUnload={Id="LightMagUnload"; Preload=true;};
	MagPrepare={Id="MagPrepare"; Preload=true;};
	LightMagLoad={Id="LightMagLoad"; Preload=true;};
};

local toolPackage = {
	ItemId="vectorx";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Submachine gun";
	Tier=4;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;