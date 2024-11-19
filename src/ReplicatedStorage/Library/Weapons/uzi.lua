local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.SMG;
	
	EquipLoadTime=0.6;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=3;
	FocusInaccuracyReduction=0;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=2;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.04;
	YRecoil=0.06;
	
	-- Weapon Properties;
	MinBaseDamage=66;
	BaseDamage=960;
	
	AmmoLimit=32;
	MaxAmmoLimit=(32*6);
	
	DamageDropoff={
		MinDistance=48;
		MaxDistance=100;
	};
	
	BaseHeadshotMultiplier=0.05;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(80);
	
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable["Submachine gun"];
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=600;
	FireRate=(60/600);
	ReloadSpeed=2.3;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16326513624;};
	PrimaryFire={Id=16326523513; FocusWeight=0.1};
	Reload={Id=16326525780;};
	TacticalReload={Id=16326511005;};
	Load={Id=16326521475;};
	Inspect={Id=16326518316;};
	Sprint={Id=16326528548};
	Empty={Id=16326515662;};
	Unequip={Id=16838914873};
	Idle={Id=17557594451};

} or { -- Main
	Core={Id=16326513624;};
	PrimaryFire={Id=16326523513; FocusWeight=0.1};
	Reload={Id=16326525780;};
	TacticalReload={Id=16326511005;};
	Load={Id=16326521475;};
	Inspect={Id=16326518316;};
	Sprint={Id=16326528548};
	Empty={Id=16326515662;};
	Unequip={Id=16838914873};
	Idle={Id=17557594451};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1926370458; Pitch=1.7; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId=script.Name;
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Submachine gun";
	Tier=5;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;