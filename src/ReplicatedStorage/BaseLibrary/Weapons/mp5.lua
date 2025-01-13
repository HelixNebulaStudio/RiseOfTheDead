local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Automatic;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	WeaponType=WeaponsAttributes.WeaponType.SMG;
	
	EquipLoadTime=0.6;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=5.2;
	FocusInaccuracyReduction=0;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.5;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.03;
	YRecoil=0.05;
	
	-- Weapon Properties;
	MinBaseDamage=22;
	BaseDamage=320;
	
	AmmoLimit=64;
	MaxAmmoLimit=(64*4);
	
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

local Animations={
	Core={Id=71683119599975;};
	PrimaryFire={Id=82588390483992; FocusWeight=0.1};
	Reload={Id=97853584691559;};
	TacticalReload={Id=100192705088254;};
	Load={Id=84472745138981;};
	Inspect={Id=91680229640429;};
	Sprint={Id=79812750977400};
	Empty={Id=78171015289849;};
	Unequip={Id=109110694888868};
	Idle={Id=74673251837991;};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1926370458; Pitch=1.1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId="mp5";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Submachine gun";
	Tier=1;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;