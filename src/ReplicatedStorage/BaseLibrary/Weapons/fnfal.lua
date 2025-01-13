local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Automatic;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	WeaponType=WeaponsAttributes.WeaponType.Rifle;
	
	EquipLoadTime=1;
	
	AmmoType="heavyammo";
	
	BaseInaccuracy=2.6;
	FocusInaccuracyReduction=0.7;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=2.5;
	InaccDecaySpeed=0.5;
	
	BulletRange=512;
	BulletEject="RifleBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.02;
	YRecoil=0.05;
	
	-- Weapon Properties;
	MinBaseDamage=42;
	BaseDamage=857;
	
	AmmoLimit=20;
	MaxAmmoLimit=(20*4);
	
	DamageDropoff={
		MinDistance=200;
		MaxDistance=400;
	};
	
	BaseHeadshotMultiplier=0.1;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Rifle;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=700;
	FireRate=(60/700);
	ReloadSpeed=1.5;
}

local Animations={
	Core={Id=136087224487951;};
	PrimaryFire={Id=120589391472868; FocusWeight=0.05};
	Reload={Id=89984982837073;};
	TacticalReload={Id=131273080192457;};
	Load={Id=98946135156629;};
	Inspect={Id=130962548424509;};
	Sprint={Id=106459353295371};
	Empty={Id=93908403390031;};
	Unequip={Id=89539360837699};
	Idle={Id=125317487530511};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1926397389; Pitch=0.6; Volume=1;};--168436671
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	Reload={Id=144798533; Pitch=1; Volume=0.6;};
}

local toolPackage = {
	ItemId="fnfal";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Rifle";
	Tier=2;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;