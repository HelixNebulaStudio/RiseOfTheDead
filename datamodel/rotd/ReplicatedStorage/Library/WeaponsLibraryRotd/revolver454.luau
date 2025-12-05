local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Pistol";
	Tier=2;

	Animations={
		Core={Id=130377150412002;};
		PrimaryFire={Id=98445409896960;};
		Reload={Id=86722699279539;};
		Load={Id=74292147267545;};
		Inspect={Id=95521544205002;};
		Sprint={Id=97133829660717};
		Unequip={Id=127466609333739};
		Empty={Id=135109263431097;};
		Idle={Id=136813651254431;};
	};

	Audio={
		Load={Id=169799883; Pitch=1.5; Volume=0.4;};
		PrimaryFire={Id=1943677171; Pitch=0.6; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		RevolverEjectBullets={Id="RevolverEjectBullets"; Preload=true;};
		RevolverBulletInsert={Id="RevolverBulletInsert"; Preload=true;};
		RevolverCloseChamber={Id="RevolverCloseChamber"; Preload=true;};
		RevolverSpinChamber={Id="RevolverSpinChamber"; Preload=true;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Semi;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		
		AmmoType="lightammo";

		BulletEject="PistolBullet";
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=260;
		PotentialDamage=3790;
		
		MagazineSize=8;
		AmmoCapacity=(8*3);
	
		Rpm=120;
		ReloadTime=4;
		Multishot=1;

		HeadshotMultiplier=0.25;
		EquipLoadTime=0.5;

		StandInaccuracy=1.5;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=1.3;

		-- Recoil
		XRecoil=0.1;
		YRecoil=0.3;
		-- Dropoff
		DamageDropoff={
			MinDistance=86;
			MaxDistance=128;
		};
		-- UI
		UISpreadIntensity=4;
		-- Body
		RecoilStregth=math.rad(90);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable.Pistol;
		-- Physics
		KillImpulseForce=5;
	};

	Properties={};
};

function toolPackage.OnReloadAnimation(handler: ToolHandlerInstance, track: AnimationTrack)
	local weaponModel = handler.MainToolModel;

	task.spawn(function()
		local speedloaderPrefab = script:WaitForChild("Speedloader");
		local speedloaderWeld = script:WaitForChild("SpeedloaderGrip");

		local newPrefab = speedloaderPrefab:Clone();
		local newWeld = speedloaderWeld:Clone();
		game.Debris:AddItem(newPrefab, 5);
		game.Debris:AddItem(newWeld, 5);
		
		local modelBase = newPrefab:WaitForChild("Speedloader");
		newPrefab.Parent = weaponModel;
		newWeld.Parent = weaponModel.Parent:FindFirstChild("LeftHand");
		newWeld.Part0 = newWeld.Parent;
		newWeld.Part1 = modelBase;

		track.Stopped:Wait();
		game.Debris:AddItem(newPrefab, 0);
		game.Debris:AddItem(newWeld, 0);
	end)
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;