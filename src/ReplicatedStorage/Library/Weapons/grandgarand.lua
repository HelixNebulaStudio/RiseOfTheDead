local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.Sniper;
	
	EquipLoadTime=1.5;
	
	AmmoType="sniperammo";
	
	BaseInaccuracy=2.4;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.5;
	MovingInaccuracyScale=8;
	
	BulletRange=512;
	BulletEject="SniperBullet";
	BulletEjectDelayTime=0.2;
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

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

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16654071483;};
	PrimaryFire={Id=16654077269; FocusWeight=1};
	Reload={Id=16654078379;};
	TacticalReload={Id=16654080664;};
	Load={Id=16654075429;};
	Inspect={Id=16654073979;};
	Sprint={Id=16654079599};
	Empty={Id=16654072549;};
	Unequip={Id=16838937257};
	Idle={Id=17557632470};
	
} or { -- Main
	Core={Id=16654071483;};
	PrimaryFire={Id=16654077269; FocusWeight=1};
	Reload={Id=16654078379;};
	TacticalReload={Id=16654080664;};
	Load={Id=16654075429;};
	Inspect={Id=16654073979;};
	Sprint={Id=16654079599};
	Empty={Id=16654072549;};
	Unequip={Id=16838937257};
	Idle={Id=17557632470};
	
};
	
local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=6548742606; Pitch=1.2; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	--Reload={Id=142491708; Pitch=1.1; Volume=0.6;};
}

local toolPackage = {
	ItemId=script.Name;
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