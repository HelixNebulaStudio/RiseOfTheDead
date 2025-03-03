local modWeaponAttributes = require(game.ReplicatedStorage.Library.Weapons.WeaponAttributes);
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Heavy machine gun";
	Tier=2;

	Animations={
		Core={Id=133095366806990;};
		PrimaryFire={Id=99653559017440; FocusWeight=0.1};
		Reload={Id=94016212826444;};
		TacticalReload={Id=89678424382639;};
		Load={Id=135446017929473;};
		Inspect={Id=105031504368390;};
		Sprint={Id=130335336647745};
		Empty={Id=117697122462602;};
		Unequip={Id=89539360837699};
		Idle={Id=113117916370922};
	};

	Audio={
		Load={Id=169799883; Pitch=0.4; Volume=0.4;};
		PrimaryFire={Id=6245184912; Pitch=1.3; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.SpinUp;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		
		AmmoType="heavyammo";

		BulletEject="ChainHeavyBullet";
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=30;
		PotentialDamage=684;
		
		MagazineSize=128;
		AmmoCapacity=(128*3);
	
		Rpm=400;
		ReloadTime=5;
		Multishot=1;
		RapidFire=12;

		HeadshotMultiplier=0.05;
		EquipLoadTime=1.5;

		StandInaccuracy=18.5;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.5;
		MovingInaccuracyScale=3;
		InaccDecaySpeed=3;

		-- Spin
		SpinUpTime = 4;
		SpinDownTime = 2;
		FullSpinInaccuracyChange=-14;
		SpinAndFire = true;

		-- Focus
		FocusWalkSpeedReduction=0.5;
		
		-- Recoil
		XRecoil=0.02;
		YRecoil=0.06;
		-- Dropoff
		DamageDropoff={
			MinDistance=192;
			MaxDistance=256;
		};
		-- UI
		UISpreadIntensity=6;
		-- Body
		RecoilStregth=math.rad(90);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable["Heavy machine gun"];
		-- Physics
		KillImpulseForce=5;
	};

	Properties={};
};


function toolPackage.OnReloadAnimation(handler: ToolHandlerInstance)
	local weaponModel = handler.Prefabs[1];

	delay(2,function()
		pcall(function()
			for a=1, 9 do
				weaponModel["Bullet0"..a].Transparency = 0;
			end
		end)
	end)
end;

function toolPackage.OnAmmoUpdate(handler: ToolHandlerInstance)
	local weaponModel = handler.Prefabs[1];
	local properties = handler.EquipmentClass.Properties;
	local ammo = properties.Ammo;

	if ammo and ammo <= 10 then
		pcall(function()
			for a=1, 9 do
				weaponModel["Bullet0"..a].Transparency = (ammo >= 10-a) and 0 or 1;
			end
		end)
	end
end;

function toolPackage.OnPrimaryFire(handler: ToolHandlerInstance)
	toolPackage.OnAmmoUpdate(handler);
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
end

return toolPackage;