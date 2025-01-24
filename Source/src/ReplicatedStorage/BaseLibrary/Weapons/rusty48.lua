local modWeaponAttributes = require(game.ReplicatedStorage.Library.Weapons.WeaponAttributes);
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Shotgun";
	Tier=4;

	Animations={
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

	Audio={
		Load={Id=169799883; Pitch=1.3; Volume=0.4;};
		PrimaryFire={Id=10400758719; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		ShotgunHandle={Id="ShotgunHandle"; Preload=true;};
		ShotgunPump2={Id="ShotgunPump2"; Preload=true;};
		LoadShotgunShell={Id="LoadShotgunShell"; Preload=true;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Automatic;
		ReloadMode=modWeaponAttributes.ReloadModes.Single;
		WeaponType=modWeaponAttributes.WeaponType.Shotgun;
		
		AmmoType="shotgunammo";

		BulletEject="ShotgunBullet";
		BulletEjectDelayTime=0.1;
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=110;
		PotentialDamage=960;
		
		MagazineSize=16;
		AmmoCapacity=(16*3);
	
		Rpm=200;
		ReloadTime=0.8;
		Multishot={Min=6, Max=7};

		HeadshotMultiplier=0.02;
		EquipLoadTime=2;

		StandInaccuracy=8;
		FocusInaccuracyReduction=0.8;
		CrouchInaccuracyReduction=0.8;
		MovingInaccuracyScale=4;
		
		Piercing=1;

		-- Recoil
		XRecoil=0.08;
		YRecoil=0.4;
		-- Dropoff
		DamageDropoff={
			MinDistance=86;
			MaxDistance=128;
		};
		-- UI
		UISpreadIntensity=8;
		-- Body
		RecoilStregth=math.rad(120);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable.Shotgun;
		-- Physics
		KillImpulseForce=20;
	};

	Properties={
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
	};
};

function toolPackage.newClass()
	local equipmentClass = modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
	
	equipmentClass:AddModifier("CriticalShot", {
		SetValues={
			CritChance=0.2;
			CritMulti=0.2;
		};
	});

	return equipmentClass;
end

return toolPackage;