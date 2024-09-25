local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Projectile;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Full;
	
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

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16692031707;};
	PrimaryFire={Id=16692041184; FocusWeight=0.2};
	Reload={Id=16692042825;};
	Inspect={Id=16692036956;};
	Load={Id=16692039191;};
	Empty={Id=16692034978;};
	Sprint={Id=16692045227};
	Unequip={Id=16840087523};
	Idle={Id=17557685365};

} or { -- Main
	Core={Id=16692031707;};
	PrimaryFire={Id=16692041184; FocusWeight=0.2};
	Reload={Id=16692042825;};
	Inspect={Id=16692036956;};
	Load={Id=16692039191;};
	Empty={Id=16692034978;};
	Sprint={Id=16692045227};
	Unequip={Id=16840087523};
	Idle={Id=17557685365};

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