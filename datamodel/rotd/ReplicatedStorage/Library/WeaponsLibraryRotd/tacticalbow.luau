local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Bow";
	Tier=3;
	
	Welds={
		LeftToolGrip="tacticalbow";
	};

	Animations={
		Core={Id=127808836086435;};
		Focus={Id=134079769374499};
		FocusCore={Id=104372864839162};
		Inspect={Id=80659276731368;};
		PrimaryFire={Id=84589890111948;};
		Reload={Id=127642469817413;};
		Load={Id=111069679794807;};
	};

	Audio={
		Load={Id=609338076; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=609348009; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0;};
		Reload={Id=609338076; Pitch=1.1; Volume=0.6;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Projectile;
		TriggerMode=modWeaponAttributes.TriggerModes.Semi;
		ReloadMode=modWeaponAttributes.ReloadModes.Single;
		
		AmmoType="lightammo";

		BulletEject="PistolBullet";
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=200;
		PotentialDamage=17800;
		
		MagazineSize=1;
		AmmoCapacity=16;
	
		Rpm=600;
		ReloadTime=1;
		Multishot=1;

		HeadshotMultiplier=0.5;
		EquipLoadTime=1.2;

		StandInaccuracy=1.8;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=1.3;

		-- Projectile
		ProjectileId="arrow";
		ProjectileConfig={
			Velocity=500;
			LifeTime=10;
			Bounce=0;
			Acceleration=Vector3.new(0, -workspace.Gravity/16, 0);
			RayRadius=0.1;
		};

		-- Focus
		CanUnfocusFire=false;
		FocusDuration=4;
		FocusWalkSpeedReduction=0.55;
		ChargeDamagePercent=1;

		-- Recoil
		XRecoil=0.0;
		YRecoil=0.0;
		-- Dropoff
		DamageDropoff={
			MinDistance=100;
			MaxDistance=200;
		};
		-- UI
		UISpreadIntensity=4;
		-- Body
		RecoilStregth=math.rad(0);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable.Pistol;
		-- Physics
		KillImpulseForce=5;
		-- Effects
		GeneratesBulletHoles=true;
		GenerateBloodEffect=true;
		GenerateTracers=false;
		GenerateMuzzle=false;
	};

	Properties={};
};

function toolPackage.OnPrimaryFire(handler: ToolHandlerInstance)
	local weaponModel = handler.Prefabs[1];
	local equipmentClass = handler.EquipmentClass;

	local arrow = weaponModel:FindFirstChild("Arrow");
	if arrow then
		arrow.Transparency = 1;
		delay(0.5, function()
			equipmentClass.Properties.OnAmmoUpdate(weaponModel, equipmentClass);
		end)
	end
end

function toolPackage.OnAmmoUpdate(handler: ToolHandlerInstance)
	local weaponModel = handler.Prefabs[1];
	local equipmentClass = handler.EquipmentClass;

	local properties = equipmentClass.Properties;
	local arrow = weaponModel:FindFirstChild("Arrow");
	
	if arrow and properties.Ammo and properties.MaxAmmo then
		arrow.Transparency = (properties.MaxAmmo <= 0 and properties.Ammo <= 0) and 1 or 0;
	end
end

function toolPackage.CustomDpsCal(handler: ToolHandlerInstance)
	local equipmentClass = handler.EquipmentClass;

	local dmg = equipmentClass.Configurations.Damage;
	local focusTime = equipmentClass.Configurations.FocusDuration;
	local reloadspeed = equipmentClass.Properties.ReloadSpeed;
	
	return dmg/focusTime;--math.max(focusTime, reloadspeed);
end

function toolPackage.CustomDpmCal(handler: ToolHandlerInstance)
	return;
end


function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;