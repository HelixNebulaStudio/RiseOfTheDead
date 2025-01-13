local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Automatic;
	ReloadMode=WeaponsAttributes.ReloadModes.Single;
	WeaponType=WeaponsAttributes.WeaponType.Shotgun;
	
	EquipLoadTime=2;
	
	AmmoType="shotgunammo";
	
	BaseInaccuracy=8;
	FocusInaccuracyReduction=0.8;
	CrouchInaccuracyReduction=0.8;
	MovingInaccuracyScale=4;
	
	BulletRange=512;
	BulletEject="ShotgunBullet";
	BulletEjectDelayTime=0.1;
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.08;
	YRecoil=0.4;
	
	-- Weapon Properties;
	MinBaseDamage=110;
	BaseDamage=960;
	
	CritChance=0.2;
	BaseCritMulti=0.2;
	
	AmmoLimit=16;
	MaxAmmoLimit=(16*3);
	
	PenatrationStrength=1; -- In studs.
	PenatrationDamageReduction=0.5; -- Damage * PenatrationDamageReduction;
	
	DamageDropoff={
		MinDistance=86;
		MaxDistance=128;
	};
	
	BaseHeadshotMultiplier=0.02;
	-- UI Configurations;
	UISpreadIntensity=8;
	
	-- Body
	RecoilStregth=math.rad(120);

	BasePiercing=1;
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Shotgun;
	
	OnAmmoUpdate = function(weaponModel, modWeaponModule)
		local properties = modWeaponModule.Properties;

		if properties.Ammo then
			local ammo = properties.Ammo;
			if ammo <= 16 then
				pcall(function()
					for a=1, 15 do
						weaponModel["Bullet0"..a].Transparency = (ammo >= 16-a) and 0 or 1;
					end
				end)
			end
		end
	end;
	KillImpulseForce=20;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=200;
	FireRate=(60/200);
	ReloadSpeed=0.8;
	BaseMultishot={Min=6, Max=7};
}

local Animations={
	Core={Id=114423274109791;};
	PrimaryFire={Id=85360180872507;};
	Reload={Id=81016526092446;};
	Load={Id=108679526346999;};
	Inspect={Id=134716749905683;};
	Sprint={Id=123254332523873};
	Empty={Id=70553285654708;};
	Unequip={Id=126196627858337};
	Idle={Id=134966070988295};
};

local Audio={
	Load={Id=169799883; Pitch=1.3; Volume=0.4;};
	PrimaryFire={Id=10400758719; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	ShotgunHandle={Id="ShotgunHandle"; Preload=true;};
	ShotgunPump2={Id="ShotgunPump2"; Preload=true;};
	LoadShotgunShell={Id="LoadShotgunShell"; Preload=true;};
}

local toolPackage = {
	ItemId="rusty48";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Shotgun";
	Tier=4;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;