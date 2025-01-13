local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Automatic;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	WeaponType=WeaponsAttributes.WeaponType.SMG;
	
	EquipLoadTime=0.6;
	UseViewModel=false;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=3;
	FocusInaccuracyReduction=0;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=2;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.04;
	YRecoil=0.06;
	
	-- Weapon Properties;
	MinBaseDamage=66;
	BaseDamage=960;
	
	AmmoLimit=80;
	MaxAmmoLimit=(80*6);
	
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

	TriggerCycleDelay=0.05;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=700;
	FireRate=(60/700);
	ReloadSpeed=2.3;
}

local Animations={
	Core={Id=126034135725918;};
	Focus={Id=118899371239210; StopOnAction=true;};
	PrimaryFire={Id=98077776698027; FocusWeight=0.1};
	Reload={Id=130544394991587;};
	TacticalReload={Id=99637654848858;};
	Load={Id=101275692995419;};
	Inspect={Id=136197119992929;};
	Sprint={Id=79145984483423};
	Empty={Id=89330626133116;};
	Unequip={Id=81815911350146};
	Idle={Id=105622842665881};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=111641686230503; Pitch=0.8; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId=script.Name;
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Submachine gun";
	Tier=5;

	Welds={
		LeftToolGrip="uzi";
		RightToolGrip="uzi";
	}
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;