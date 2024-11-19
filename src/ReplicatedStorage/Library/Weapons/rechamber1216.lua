local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.Shotgun;
	
	EquipLoadTime=2;
	
	AmmoType="shotgunammo";
	
	BaseInaccuracy=4;
	FocusInaccuracyReduction=0.8;
	CrouchInaccuracyReduction=0.8;
	MovingInaccuracyScale=4;
	
	BulletRange=512;
	BulletEject="ShotgunBullet";
	BulletEjectDelayTime=0.1;
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.08;
	YRecoil=0.4;
	
	-- Weapon Properties;
	MinBaseDamage=80;
	BaseDamage=2460;
	
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
	UISpreadIntensity=6;
	
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
				-- pcall(function()
				-- 	for a=1, 15 do
				-- 		weaponModel["Bullet0"..a].Transparency = (ammo >= 16-a) and 0 or 1;
				-- 	end
				-- end)
			end
		end
	end;
	KillImpulseForce=20;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=100;
	FireRate=(60/100);
	ReloadSpeed=3;
	BaseMultishot={Min=4, Max=4};
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16311093189;};
	PrimaryFire={Id=16311102924;};
	Reload={Id=16311104731;};
	Load={Id=16311101004;};
	Inspect={Id=16311099151;};
	Sprint={Id=16311107195};
	Empty={Id=16311095884;};
	Unequip={Id=16838914873};
	Idle={Id=17557363942};

} or { -- Main
	Core={Id=16311093189;};
	PrimaryFire={Id=16311102924;};
	Reload={Id=16311104731;};
	Load={Id=16311101004;};
	Inspect={Id=16311099151;};
	Sprint={Id=16311107195};
	Empty={Id=16311095884;};
	Unequip={Id=16838914873};
	Idle={Id=17557363942};
	
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
	ItemId=script.Name;
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Shotgun";
	Tier=5;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;