local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Projectile;
	TriggerMode=WeaponsAttributes.TriggerModes.Semi;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	
	EquipLoadTime=1.2;
	
	BaseInaccuracy=1.8;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	
	-- Weapon Properties;
	MinBaseDamage=420;
	BaseDamage=14000;
	
	AmmoLimit=9;
	MaxAmmoLimit=(9*3);
	
	XRecoil=0.06;
	YRecoil=0.1;
	
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);
	WaistRotation=math.rad(85);--75
	
	-- Decorations;
	ShakeCamera=false;
	GeneratesBulletHoles=false;
	GenerateBloodEffect=false;
	GenerateTracers=false;
	
	-- Projectile Configurations;
	ProjectileId="50mmGrenade";
	AdsTrajectory=true;
	
	ExplosionRadius=12;
	ExplosionStun=1;
	
	--
	FocusWalkSpeedReduction=0.55;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=66;
	FireRate=(60/66);
	ReloadSpeed=3;
	BasePotential=0.35;
}

local Animations={
	Core={Id=94828859106600;};
	PrimaryFire={Id=104759963599356; FocusWeight=0.2};
	Reload={Id=70499051411013;};
	Inspect={Id=122320237597281;};
	Load={Id=100129964580240;};
	Empty={Id=99515397778043;};
	Sprint={Id=107005249042028};
	Unequip={Id=105508427477788};
	Idle={Id=98099690709645};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=9140961699; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
}

local toolPackage = {
	ItemId="grenadelauncher";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Explosive";
	Tier=2;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;