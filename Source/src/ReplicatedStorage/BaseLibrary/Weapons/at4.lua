local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Projectile;
	TriggerMode=WeaponsAttributes.TriggerModes.Semi;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	
	EquipLoadTime=2;
	
	BaseInaccuracy=5;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	
	-- Weapon Properties;
	MinBaseDamage=960;
	BaseDamage=24480;
	
	AmmoLimit=1;
	MaxAmmoLimit=(1*8);
	
	XRecoil=0.05;
	YRecoil=0.05;
	
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);

	-- Decorations;
	ShakeCamera=false;
	GeneratesBulletHoles=false;
	GenerateBloodEffect=false;
	GenerateTracers=false;
	
	-- Projectile Configurations;
	ProjectileId="rpgRocket";
	AdsTrajectory=true;
	
	ExplosionRadius=20;
	ExplosionStun=2.5;
	
	--
	FocusWalkSpeedReduction=0.5;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=120;
	FireRate=(60/120);--240
	ReloadSpeed=2.6;
	BasePotential=0.1;
}

local Animations = {
	Core={Id=87795068281795;};
	Inspect={Id=97393780176378;};
	Load={Id=139798738341805;};
	PrimaryFire={Id=109792870472592; FocusWeight=0.2};
	Empty={Id=90459133505253;};
	Reload={Id=113510205572789;};
	Sprint={Id=134668962157630};
	Unequip={Id=76549187208665};
	Idle={Id=135526876095084};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1420705976; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	Reload={Id=6456497676; Pitch=1.1; Volume=0.6;};
	ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
}

local toolPackage = {
	ItemId="at4";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Explosive";
	Tier=3;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;