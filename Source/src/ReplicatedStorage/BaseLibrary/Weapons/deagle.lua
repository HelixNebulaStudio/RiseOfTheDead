local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Semi;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	
	EquipLoadTime=0.5;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=4;
	FocusInaccuracyReduction=0.7;
	CrouchInaccuracyReduction=0.7;
	MovingInaccuracyScale=1.6;
	
	BulletRange=512;
	BulletEject="DeagleBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.1;
	YRecoil=0.24;
	
	-- Weapon Properties;
	MinBaseDamage=260;
	BaseDamage=5200;
	
	AmmoLimit=8;
	MaxAmmoLimit=(8*4);
	
	DamageDropoff={
		MinDistance=86;
		MaxDistance=128;
	};
	
	BaseHeadshotMultiplier=1;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);

	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Pistol;
	
	-- Focus
	BaseFocusDuration=0.5;
	FocusDuration=1;
	FocusWalkSpeedReduction=0.65;
	ChargeDamagePercent=0.5;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=266;
	FireRate=(60/266);
	ReloadSpeed=3;
}

local Animations={
	Core={Id=86638305514387;};
	Load={Id=71655578766028;};
	PrimaryFire={Id=130434666154513;};
	Reload={Id=105967635270888;};
	TacticalReload={Id=134104462785864;};
	Inspect={Id=79093773598307;};
	Empty={Id=104090479951422;};
	Sprint={Id=93820486544159};
	Idle={Id=128179753706471;};
	Unequip={Id=127466609333739};
};

local Audio={
	Load={Id=169799883; Pitch=1.5; Volume=0.4;};
	PrimaryFire={Id=1943677171; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId="deagle";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Pistol";
	Tier=3;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;