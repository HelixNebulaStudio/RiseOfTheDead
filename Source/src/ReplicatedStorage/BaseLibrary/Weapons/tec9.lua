local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Automatic;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	
	EquipLoadTime=0.5;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=2.6;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.6;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.1;
	YRecoil=0.15;
	
	-- Weapon Properties;
	MinBaseDamage=25;
	BaseDamage=365;
	
	AmmoLimit=24;
	MaxAmmoLimit=(24*4);
	
	DamageDropoff={
		MinDistance=86;
		MaxDistance=128;
	};
	
	BaseHeadshotMultiplier=0.5;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);
	
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Pistol;
}

local Properties={
	Rpm=500;
	FireRate=(60/500);
	ReloadSpeed=3;
}

local Animations={
	Core={Id=135133469120520;};
	Load={Id=125430962645689;};
	PrimaryFire={Id=115330496659351;};
	Reload={Id=85283806936476;};
	TacticalReload={Id=126237372621444;};
	Inspect={Id=120312329588174;};
	Empty={Id=104139692343421;};
	Sprint={Id=98761523775318};
	Idle={Id=108307845393807;};
	Unequip={Id=127466609333739};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.1; Volume=0.4;};
	PrimaryFire={Id=273605833; Pitch=1.5; Volume=0.6;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId="tec9";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Pistol";
	Tier=1;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;