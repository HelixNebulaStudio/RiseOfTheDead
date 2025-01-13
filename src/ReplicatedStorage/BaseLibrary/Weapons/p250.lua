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

	-- Weapon Properties;
	MinBaseDamage=25;
	BaseDamage=365;
	
	AmmoLimit=15;
	MaxAmmoLimit=(15*5);

	DamageDropoff={
		MinDistance=100;
		MaxDistance=200;
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
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=330;
	FireRate=(60/330);
	ReloadSpeed=2.5;
}

local Animations={
	Core={Id=106976440089912;};
	PrimaryFire={Id=132256512276284;};
	Reload={Id=89576125275043;};
	TacticalReload={Id=136987069567609;};
	Load={Id=70396905445589;};
	Inspect={Id=88589264816751;};
	Sprint={Id=133455721075571};
	Empty={Id=105278438776505;};
	Unequip={Id=127466609333739};
	Idle={Id=115776351566455;};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=2920959; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	LightSlidePull={Id="LightSlidePull"; Preload=true;};
	LightSlideRelease={Id="LightSlideRelease"; Preload=true;};
	LightMagLoad={Id="LightMagLoad"; Preload=true;};
	LightMagUnload={Id="LightMagUnload"; Preload=true;};
};

local toolPackage = {
	ItemId="p250";
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