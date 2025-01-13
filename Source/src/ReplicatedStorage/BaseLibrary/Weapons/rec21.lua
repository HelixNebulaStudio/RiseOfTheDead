local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Semi;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	WeaponType=WeaponsAttributes.WeaponType.Sniper;
	
	EquipLoadTime=1.5;
	
	AmmoType="sniperammo";
	
	BaseInaccuracy=2.4;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.5;
	MovingInaccuracyScale=8;
	
	BulletRange=512;
	BulletEject="SniperBullet";
	BulletEjectDelayTime=0.2;
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.1;
	YRecoil=0.6;
	
	-- Weapon Properties;
	MinBaseDamage=650;
	BaseDamage=16575;
	
	AmmoLimit=10;
	MaxAmmoLimit=(10*3);
	
	DamageDropoff={
		MinDistance=256;
	};
	
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);

	UseScopeGui=true;
	
	-- Sniper
	BaseFocusDuration=4;
	FocusDuration=4;
	FocusWalkSpeedReduction=0.65;
	ChargeDamagePercent=0.2;
	
	Penetration=WeaponProperties.PenetrationTable.Sniper;
	KillImpulseForce=40;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=60;
	FireRate=(60/60);
	ReloadSpeed=3.2;
}

local Animations={
	Core={Id=112622547108213;};
	PrimaryFire={Id=81791535018205; FocusWeight=1};
	Reload={Id=130398168625268;};
	TacticalReload={Id=139685511777769;};
	Load={Id=126717541041189;};
	Inspect={Id=72743764822617;};
	Sprint={Id=106100474749178};
	Empty={Id=95349036734819;};
	Unequip={Id=130105436052579};
	Idle={Id=125865165336390};
};
	
local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=6548742606; Pitch=1.2; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId="rec21";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Sniper";
	Tier=2;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;