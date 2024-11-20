local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Full;
	
	EquipLoadTime=0.5;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=4;
	FocusInaccuracyReduction=0.7;
	CrouchInaccuracyReduction=0.7;
	MovingInaccuracyScale=1.6;
	
	BulletRange=512;
	BulletEject="DeagleBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

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

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16238141190;};
	Load={Id=16238153881;};
	PrimaryFire={Id=16238156123;};
	Reload={Id=16238158414;};
	TacticalReload={Id=16238160585;};
	Inspect={Id=16238150963;};
	Empty={Id=16238147889;};
	Sprint={Id=16184602077};
	Idle={Id=17557221759;};
	Unequip={Id=16838903122};
	
} or {
	Core={Id=16678377645;};
	Load={Id=16678381083;};
	PrimaryFire={Id=16678383172;};
	Reload={Id=16678396492;};
	TacticalReload={Id=16678406960;};
	Inspect={Id=16678413893;};
	Empty={Id=16678416286;};
	Sprint={Id=16678418213};
	Idle={Id=17557221759;};
	Unequip={Id=16838903122};
	
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