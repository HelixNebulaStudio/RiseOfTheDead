local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.SpinUp;
	ReloadMode=Library.ReloadModes.Full;
	
	EquipLoadTime=1.3;
	
	AmmoType="heavyammo";
	
	BaseInaccuracy=5.5;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.5;
	MovingInaccuracyScale=3;
	InaccDecaySpeed=6;
	
	BulletRange=512;
	BulletEject="HeavyBullet";
	
	XRecoil=0.03;
	YRecoil=0.08;
	
	SpinUpTime = 1;
	SpinDownTime = 1.1;
	-- Weapon Properties;
	MinBaseDamage=20;
	BaseDamage=456;
	
	AmmoLimit=128;
	MaxAmmoLimit=(128*4);
	
	DamageDropoff={
		MinDistance=222;
		MaxDistance=256;
	};
	
	BaseHeadshotMultiplier=0.1;
	-- UI Configurations;
	UISpreadIntensity=5;
	
	-- Body
	RecoilStregth=math.rad(90);
	WaistRotation=math.rad(75);
	
	FocusWalkSpeedReduction=0.5;
	
	Penetration=WeaponProperties.PenetrationTable["Heavy machine gun"];
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=800;
	FireRate=(60/800);
	ReloadSpeed=6;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16544954964;};
	PrimaryFire={Id=16544958484; FocusWeight=0.1};
	Reload={Id=16544966221;};
	Load={Id=16544964245;};
	Inspect={Id=16544961584;};
	Sprint={Id=16544973428};
	Empty={Id=16544956589;};
	SpinUp={Id=16544968782;};
	
} or { -- Main
	Core={Id=16544954964;};
	PrimaryFire={Id=16544958484; FocusWeight=0.1};
	Reload={Id=16544966221;};
	Load={Id=16544964245;};
	Inspect={Id=16544961584;};
	Sprint={Id=16544973428};
	Empty={Id=16544956589;};
	SpinUp={Id=16544968782;};
	
};


local Audio={
	Load={Id=169799883; Pitch=0.4; Volume=0.4;};
	PrimaryFire={Id=1884320340; Pitch=1; Volume=1; Looped=true};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	SpinUp={Id=1896997630; Pitch=1; Volume=0.6;};
	SpinDown={Id=1896998615; Pitch=1; Volume=0.6;};
}

local toolPackage = {
	ItemId="minigun";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Heavy machine gun";
	Tier=1;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;