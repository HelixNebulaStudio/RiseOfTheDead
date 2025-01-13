local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Semi;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	WeaponType=WeaponsAttributes.WeaponType.Sniper;
	
	EquipLoadTime=1.65;
	
	AmmoType="sniperammo";
	
	BaseInaccuracy=2;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.5;
	MovingInaccuracyScale=8;
	
	BulletRange=512;
	BulletEject="SniperBullet";
	BulletEjectDelayTime=0.1;
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.12;
	YRecoil=0.56;
	
	-- Weapon Properties;
	MinBaseDamage=420;
	BaseDamage=10710;
	
	AmmoLimit=7;
	MaxAmmoLimit=(7*4);
	
	DamageDropoff={
		MinDistance=240;
	};
	
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);
	
	UseScopeGui=true;
	
	-- Sniper
	BaseFocusDuration=3;
	FocusDuration=3;
	FocusWalkSpeedReduction=0.6;
	ChargeDamagePercent=0.2;

	Penetration=WeaponProperties.PenetrationTable.Sniper;
	KillImpulseForce=40;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=41.24;
	FireRate=(60/41.24);
	ReloadSpeed=3;
}

local Animations={
	Core={Id=107319034723073;};
	PrimaryFire={Id=76079258310936; FocusWeight=1};
	PrimaryFire2={Id=129233040725131; FocusWeight=1};
	Reload={Id=102548326261820;};
	TacticalReload={Id=129855725382622;};
	Load={Id=136249237336011;};
	Inspect={Id=85477377086473;};
	Sprint={Id=102473595783859};
	Empty={Id=97628151291748;};
	Unequip={Id=130105436052579};
	Idle={Id=120549342699367};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1953832141; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId="awp";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Sniper";
	Tier=1;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;