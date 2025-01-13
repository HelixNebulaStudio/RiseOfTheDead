local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Semi;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	
	EquipLoadTime=0.5;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=2;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.02;
	YRecoil=0.04;
	
	-- Weapon Properties;
	MinBaseDamage=65;
	BaseDamage=950;
	
	AmmoLimit=15;
	MaxAmmoLimit=(15*4);
	
	DamageDropoff={
		MinDistance=86;
		MaxDistance=128;
	};
	
	BaseHeadshotMultiplier=1.5;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);

	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Pistol;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=300;
	FireRate=(60/300);
	ReloadSpeed=3;
}

local Animations={
	Core={Id=96110447359788;};
	Load={Id=94539982728281;};
	PrimaryFire={Id=80035842198542;};
	Reload={Id=127297547906446;};
	Inspect={Id=138270425682397;};
	Empty={Id=100802504065200;};
	Unequip={Id=127466609333739};
	TacticalReload={Id=86523319939547;};
	Idle={Id=73258199716672;};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=2757012511; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
};

local toolPackage = {
	ItemId="m9legacy";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Pistol";
	Tier=2;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;